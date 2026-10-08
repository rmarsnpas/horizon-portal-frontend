# ============================================================
# Horizon House --- Outlook Scan Inbox Watcher  (with OCR)
# ============================================================
# Same job as auto-doc-inbox.ps1, but the "inbox" is an Outlook
# mailbox folder instead of a Windows folder. Use this when the
# Ricoh scans directly to a shared/dedicated email address
# (Scan to Email) instead of to a shared network folder.
#
# Requires: classic Outlook desktop (Win32, NOT "new Outlook")
# installed, signed in, and running on THIS computer, with the
# scan mailbox added so it shows in the Outlook folder pane.
# This script must run on the computer that is physically near
# (or at least has Outlook configured for) that mailbox -
# typically the work PC, not a laptop that never opens Outlook.
#
# What it does, every $POLL_SECONDS:
#   1. Looks at every email sitting in the mailbox's Inbox
#   2. For each PDF/image attachment:
#      a. Try to find the member ID in the attachment filename
#         or the email Subject (fastest - type the ID on the
#         Ricoh touchscreen before scanning, e.g. "0133")
#      b. If not found, run OCR on the page to read the name/ID
#      c. Detect the document type (Drug Screen, Agreement, etc.)
#      d. Upload to the member's file cabinet
#      e. Save a local copy into Members\###-First Last\
#   3. Moves the email to "Processed" (all attachments matched)
#      or "Review" (could not identify - OCR text is attached to
#      the email itself so you can see what was read) under the
#      mailbox's Inbox.
# ============================================================

# ------ Configuration --------------------------------------------------------------------------
# Must match the mailbox's name EXACTLY as it appears in Outlook's folder pane
# (left sidebar) on this PC - usually the email address or display name.
$MAILBOX_NAME    = "scandocs@horizon-house.org"
# Folder path under that mailbox to watch. Use "Inbox\\Scans" if you set up
# an Outlook rule that files scan emails into a "Scans" subfolder instead.
$INBOX_PATH      = "Inbox"
$API_BASE        = "https://horizon-portal-backend-production-3532.up.railway.app/api"
$MembersDir      = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\Members"
$DEFAULT_TYPE    = "General"
$POLL_SECONDS    = 30
$VALID_EXT       = @('.pdf', '.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff', '.doc', '.docx')
# ------------------------------------------------------------------------------------------------

$StagingDir = Join-Path $env:TEMP "HorizonOutlookScanStaging"
$LogFile    = Join-Path $StagingDir "upload-log.txt"
@($MembersDir, $StagingDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

function Write-Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Host $line
    try { Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
}

# ------ WinRT async helper (OCR) -----------------------------------------------------------------
Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null

function Await {
    param($WinRtTask)
    try {
        $timeout = 30000
        $waited = 0
        while ($WinRtTask.Status -eq 0 -and $waited -lt $timeout) {
            Start-Sleep -Milliseconds 100
            $waited += 100
        }
        if ($waited -ge $timeout) { throw "WinRT async operation timed out after 30 seconds" }
        if ($WinRtTask.Status -eq 3) { throw "WinRT async operation failed" }
        if ($WinRtTask.Status -eq 2) { throw "WinRT async operation was canceled" }
        try { return $WinRtTask.GetResults() } catch { return $null }
    } catch {
        Write-Log "  Await error: $($_.Exception.Message)"
        throw
    }
}

function Load-WinRTTypes {
    try {
        [Windows.Media.Ocr.OcrEngine,           Windows.Foundation, ContentType=WindowsRuntime] | Out-Null
        [Windows.Storage.StorageFile,            Windows.Foundation, ContentType=WindowsRuntime] | Out-Null
        [Windows.Storage.StorageFolder,          Windows.Foundation, ContentType=WindowsRuntime] | Out-Null
        [Windows.Storage.FileAccessMode,         Windows.Foundation, ContentType=WindowsRuntime] | Out-Null
        [Windows.Graphics.Imaging.BitmapDecoder, Windows.Foundation, ContentType=WindowsRuntime] | Out-Null
        [Windows.Graphics.Imaging.SoftwareBitmap,Windows.Foundation, ContentType=WindowsRuntime] | Out-Null
        [Windows.Data.Pdf.PdfDocument,           Windows.Foundation, ContentType=WindowsRuntime] | Out-Null
        [Windows.Data.Pdf.PdfPageRenderOptions,  Windows.Foundation, ContentType=WindowsRuntime] | Out-Null
        return $true
    } catch {
        Write-Log "WARNING: Could not load Windows OCR libraries: $_"
        Write-Log "         OCR disabled. Staff must type the member ID in the filename or email subject."
        return $false
    }
}

function Render-PdfFirstPage($pdfPath) {
    try {
        $tempPdf = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "ocr_temp_$(Get-Random).pdf")
        Copy-Item -Path $pdfPath -Destination $tempPdf -Force
        $tmpPng  = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.png')

        $sf    = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($tempPdf))
        $pdf   = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($sf))
        if ($pdf.PageCount -eq 0) {
            Remove-Item $tempPdf -Force -ErrorAction SilentlyContinue
            return $null
        }
        $page  = $pdf.GetPage(0)

        $tmpDir  = [System.IO.Path]::GetDirectoryName($tmpPng)
        $tmpName = [System.IO.Path]::GetFileName($tmpPng)
        $folder  = Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($tmpDir))
        $outFile = Await ($folder.CreateFileAsync($tmpName, [Windows.Storage.CreationCollisionOption]::ReplaceExisting))
        $stream  = Await ($outFile.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite))

        $opts = New-Object Windows.Data.Pdf.PdfPageRenderOptions
        $opts.DestinationHeight = 2400
        Await ($page.RenderToStreamAsync($stream, $opts))
        $stream.Dispose()
        $page.Dispose()

        Remove-Item $tempPdf -Force -ErrorAction SilentlyContinue
        return $tmpPng
    } catch {
        Write-Log "  OCR: PDF render failed: $_"
        return $null
    }
}

function Get-OcrTextFromImage($imagePath) {
    try {
        $ext = [System.IO.Path]::GetExtension($imagePath)
        $tempImage = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "ocr_img_$(Get-Random)$ext")
        Copy-Item -Path $imagePath -Destination $tempImage -Force

        $engine  = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
        if (-not $engine) {
            Write-Log "  OCR engine initialization failed - Windows OCR not available"
            Remove-Item $tempImage -Force -ErrorAction SilentlyContinue
            return ''
        }

        $sf      = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($tempImage))
        $stream  = Await ($sf.OpenAsync([Windows.Storage.FileAccessMode]::Read))
        $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream))
        $bitmap  = Await ($decoder.GetSoftwareBitmapAsync())
        $result  = Await ($engine.RecognizeAsync($bitmap))
        $stream.Dispose()

        Remove-Item $tempImage -Force -ErrorAction SilentlyContinue
        return $result.Text
    } catch {
        Write-Log "  OCR: Image read failed: $_"
        return ''
    }
}

function Get-OcrText($filePath) {
    if (-not $script:_ocrEnabled) { return '' }
    $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
    $tmpFile = $null
    try {
        if ($ext -eq '.pdf') {
            $tmpFile = Render-PdfFirstPage $filePath
            if (-not $tmpFile -or -not (Test-Path $tmpFile)) { return '' }
            return Get-OcrTextFromImage $tmpFile
        } elseif ($ext -in @('.jpg','.jpeg','.png','.bmp','.tif','.tiff')) {
            return Get-OcrTextFromImage $filePath
        } else { return '' }
    } finally {
        if ($tmpFile -and (Test-Path $tmpFile)) { Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue }
    }
}

function Find-MemberInOcrText($ocrText, $members) {
    if (-not $ocrText) { return $null }
    $text = $ocrText.ToLower()

    foreach ($dm in [regex]::Matches($ocrText, '\b(\d{2,4})\b')) {
        $m = Find-MemberById $members $dm.Groups[1].Value
        if ($m) { return @{ member=$m; confidence='high'; via="ID $($dm.Groups[1].Value)" } }
    }
    foreach ($m in $members) {
        $fn = (Get-PropValue $m @('FIRST','first','FIRST NAME','FIRST\r\nNAME','FIRST\nNAME','firstName')).ToLower().Trim()
        $ln = (Get-PropValue $m @('LAST','last','LAST NAME','LAST\r\nNAME','LAST\nNAME','lastName')).ToLower().Trim()
        if ($fn.Length -lt 2 -or $ln.Length -lt 2) { continue }
        if ($text -match [regex]::Escape($fn) -and $text -match [regex]::Escape($ln)) {
            return @{ member=$m; confidence='high'; via="full name ($fn $ln)" }
        }
    }
    foreach ($m in $members) {
        $ln = (Get-PropValue $m @('LAST','last','LAST NAME','LAST\r\nNAME','LAST\nNAME','lastName')).ToLower().Trim()
        if ($ln.Length -lt 3) { continue }
        if ($text -match "\b$([regex]::Escape($ln))\b") {
            return @{ member=$m; confidence='low'; via="last name only ($ln)" }
        }
    }
    return $null
}

function Get-DocTypeFromOcrText($ocrText) {
    if (-not $ocrText) { return $null }
    $t = $ocrText.ToLower()
    if ($t -match 'drug screen|urinalysis|\bua\b|urine|drug test')        { return 'Drug Screen' }
    if ($t -match "driver.?s license|state id|identification card")      { return 'ID / License' }
    return $null
}

# ------ Member helpers ---------------------------------------------------------------------------
function Get-PropValue($obj, [string[]]$keys) {
    foreach ($k in $keys) { $v = $obj.$k; if ($null -ne $v -and $v -ne '') { return [string]$v } }
    return ''
}
function Find-MemberById($members, $rawId) {
    $id = ([string]$rawId).TrimStart('0')
    foreach ($m in $members) {
        $mid = (Get-PropValue $m @('ID','id','MEMBER ID')).TrimStart('0')
        if ($mid -eq $id) { return $m }
    }
    return $null
}
function Get-MemberName($m) {
    $f = Get-PropValue $m @('FIRST','first','FIRST_NAME','FIRST NAME',"FIRST`r`nNAME","FIRST`nNAME",'firstName')
    $l = Get-PropValue $m @('LAST','last','LAST_NAME','LAST NAME',"LAST`r`nNAME","LAST`nNAME",'lastName')
    return "$f $l".Trim()
}
function Get-MemberFolder($member, $rawId) {
    $numericId = 0
    if (-not [int]::TryParse(([string]$rawId).Trim(), [ref]$numericId)) {
        throw "Cannot create member folder because '$rawId' is not a numeric member ID."
    }
    $folderId = $numericId.ToString('000')
    $memberName = Get-MemberName $member
    $safeName = ($memberName -replace '[<>:"/\\|?*]', '').Trim().TrimEnd('.')
    if (-not $safeName) { $safeName = 'Unknown Member' }

    $idPattern = '^0*' + [regex]::Escape($numericId.ToString()) + '(?:-|\s|$)'
    $existingFolder = Get-ChildItem -Path $MembersDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $idPattern } |
        Select-Object -First 1
    if ($existingFolder) { return $existingFolder.FullName }

    $memberFolder = Join-Path $MembersDir "$folderId-$safeName"
    New-Item -ItemType Directory -Path $memberFolder -Force -ErrorAction Stop | Out-Null
    Write-Log "  Created member folder: $folderId-$safeName"
    return $memberFolder
}
function Copy-ToMemberFolder($filePath, $filename, $member, $memberId) {
    $memberFolder = Get-MemberFolder $member $memberId
    $destination = Join-Path $memberFolder $filename
    if (Test-Path $destination) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
        $extension = [System.IO.Path]::GetExtension($filename)
        $destination = Join-Path $memberFolder ("{0}_{1}{2}" -f $baseName, (Get-Date -Format 'yyyyMMdd_HHmmss'), $extension)
    }
    Copy-Item -Path $filePath -Destination $destination -Force -ErrorAction Stop
    return $destination
}
function Get-Members {
    try {
        $all = Invoke-RestMethod -Uri "$API_BASE/members?compact=1" -Method GET -TimeoutSec 15
        if (-not $all) { Write-Log "  WARNING: API returned null/empty"; return $null }
        return $all
    } catch {
        Write-Log "ERROR fetching members: $($_.Exception.Message)"
        return $null
    }
}

# ------ Text-based ID / doc-type detection (works on filename OR email subject) ------------------
function Get-MemberIdFromText($members, $text) {
    if (-not $text) { return $null }
    $base = $text.ToLower()

    if ($base -match '(?:member\s*)?id[\s:-]*?(\d{2,9})\b') {
        return $matches[1]
    }
    if ($base -match '^(\d{2,9})(?:\D|$)') {
        return $matches[1]
    }
    $nums = [regex]::Matches($base, '\b(\d{2,9})\b')
    if ($nums.Count -gt 0) {
        foreach ($n in $nums) {
            if (Find-MemberById $members $n.Groups[1].Value) { return $n.Groups[1].Value }
        }
    }
    return $null
}
function Get-DocTypeFromFilename($filename) {
    $l = $filename.ToLower()
    if ($l -match 'agree|contract')               { return 'Agreement' }
    if ($l -match 'letter|ltr')                   { return 'Letter' }
    if ($l -match 'roi|release')                  { return 'Release of Information' }
    if ($l -match 'drug.?screen|ua\b|urinalysis') { return 'Drug Screen' }
    if ($l -match 'incident|report')              { return 'Incident Report' }
    if ($l -match '\bid\b|license|passport')      { return 'ID / License' }
    if ($l -match 'insurance')                    { return 'Insurance Card' }
    if ($l -match 'court|probation|parole')       { return 'Court Document' }
    if ($l -match 'application|app\b')            { return 'Application' }
    if ($l -match 'medical|med\b|rx')             { return 'Medical Record' }
    return $DEFAULT_TYPE
}

# ------ Upload file to portal ---------------------------------------------------------------------
function Upload-File($filePath, $memberId, $memberName, $docType) {
    $filename    = [System.IO.Path]::GetFileName($filePath)
    $contentType = switch -Regex ($filename.ToLower()) {
        '\.pdf$'        { 'application/pdf' }
        '\.(jpg|jpeg)$' { 'image/jpeg' }
        '\.png$'        { 'image/png' }
        '\.doc$'  { 'application/msword' }
        '\.docx$' { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
        default         { 'application/octet-stream' }
    }
    $boundary  = [System.Guid]::NewGuid().ToString()
    $LF        = "`r`n"
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
    $enc       = [System.Text.Encoding]::UTF8
    $hdr = ''
    foreach ($f in @(@{n='memberId';v=$memberId},@{n='memberName';v=$memberName},@{n='docType';v=$docType},@{n='notes';v=$filename})) {
        $hdr += "--$boundary$LF"; $hdr += "Content-Disposition: form-data; name=`"$($f.n)`"$LF$LF"; $hdr += "$($f.v)$LF"
    }
    $hdr += "--$boundary$LF"
    $hdr += "Content-Disposition: form-data; name=`"document`"; filename=`"$filename`"$LF"
    $hdr += "Content-Type: $contentType$LF$LF"
    $pre = $enc.GetBytes($hdr); $post = $enc.GetBytes("$LF--$boundary--$LF")
    $body = New-Object byte[] ($pre.Length + $fileBytes.Length + $post.Length)
    [System.Buffer]::BlockCopy($pre,       0, $body, 0,                               $pre.Length)
    [System.Buffer]::BlockCopy($fileBytes, 0, $body, $pre.Length,                     $fileBytes.Length)
    [System.Buffer]::BlockCopy($post,      0, $body, $pre.Length + $fileBytes.Length, $post.Length)
    return Invoke-RestMethod -Uri "$API_BASE/member-documents/upload" -Method POST `
        -ContentType "multipart/form-data; boundary=$boundary" -Body $body -TimeoutSec 60
}

# ------ Outlook helpers ----------------------------------------------------------------------------
function Get-MailboxRoot($ns, $name) {
    foreach ($f in $ns.Folders) { if ($f.Name -ieq $name) { return $f } }
    foreach ($f in $ns.Folders) { if ($f.Name -match [regex]::Escape($name)) { return $f } }
    return $null
}
function Get-SubFolder($parent, $path) {
    $cur = $parent
    foreach ($seg in ($path -split '\\')) {
        if (-not $seg) { continue }
        try { $cur = $cur.Folders.Item($seg) }
        catch { throw "Folder '$seg' not found under '$($parent.Name)'. Check `$INBOX_PATH." }
    }
    return $cur
}
function Get-OrCreateChildFolder($parent, $name) {
    try { return $parent.Folders.Item($name) }
    catch { return $parent.Folders.Add($name) }
}

# ---------------------------------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------------------------------
Write-Log "=== Horizon House Outlook Scan Inbox Watcher ==="
Write-Log "Mailbox  : $MAILBOX_NAME"
Write-Log "Folder   : $INBOX_PATH"
Write-Log "Press Ctrl+C to stop."
Write-Log ""

$script:_ocrEnabled = Load-WinRTTypes
Write-Log $(if ($script:_ocrEnabled) { "OCR: ENABLED -- will read document content to identify members." } else { "OCR: DISABLED --- scans must have the member ID in the filename or email subject." })
Write-Log ""

Write-Log "Connecting to Outlook..."
try {
    $outlook = New-Object -ComObject Outlook.Application
    $ns      = $outlook.GetNamespace("MAPI")
} catch {
    Write-Log "ERROR: Could not start Outlook. Make sure classic Outlook desktop is installed on this PC."
    Write-Log "       $_"
    exit 1
}

$mailboxRoot = Get-MailboxRoot $ns $MAILBOX_NAME
if (-not $mailboxRoot) {
    Write-Log "ERROR: Could not find a mailbox named '$MAILBOX_NAME' in Outlook's folder pane."
    Write-Log "       Add the mailbox to Outlook first (see INBOX_SETUP_GUIDE.html), or fix `$MAILBOX_NAME at the top of this script to match exactly."
    exit 1
}
$watchFolder     = Get-SubFolder $mailboxRoot $INBOX_PATH
$processedFolder = Get-OrCreateChildFolder $watchFolder "Processed"
$reviewFolder    = Get-OrCreateChildFolder $watchFolder "Review"
Write-Log "Connected. Watching '$($mailboxRoot.Name)\$INBOX_PATH' -- $($watchFolder.Items.Count) item(s) currently waiting."
Write-Log ""

$members        = $null
$lastMemberLoad = [datetime]::MinValue
$olMailItemClass = 43

while ($true) {
    if (-not $members -or ([datetime]::Now - $lastMemberLoad).TotalHours -gt 1) {
        Write-Log "Loading member list..."
        $members = Get-Members
        if ($null -ne $members -and $members.Count -gt 0) {
            $lastMemberLoad = [datetime]::Now
            Write-Log "Loaded $($members.Count) members."
        } else {
            Write-Log "Cannot reach server or 0 members returned --- retrying in $POLL_SECONDS s."
            Start-Sleep -Seconds $POLL_SECONDS
            continue
        }
    }

    # Iterate from the end backwards -- items get Moved out of this folder as
    # they're handled, which would otherwise shift indexes mid-loop.
    $count = $watchFolder.Items.Count
    for ($i = $count; $i -ge 1; $i--) {
        $mail = $watchFolder.Items.Item($i)
        if ($mail.Class -ne $olMailItemClass) { continue }

        $subject = [string]$mail.Subject
        Write-Log "------------------------------------------------------------------------------"
        Write-Log "Email: $subject"

        $attachments = @($mail.Attachments) | Where-Object {
            $VALID_EXT -contains [System.IO.Path]::GetExtension($_.FileName).ToLower()
        }

        if ($attachments.Count -eq 0) {
            Write-Log "  No usable attachments --- moved to Review."
            try { $mail.Move($reviewFolder) | Out-Null } catch { Write-Log "  Could not move email: $_" }
            continue
        }

        $allMatched  = $true
        $reviewNotes = @()

        foreach ($att in $attachments) {
            $filename = $att.FileName
            $stagedPath = Join-Path $StagingDir "$(Get-Random)_$filename"
            try {
                $att.SaveAsFile($stagedPath)
            } catch {
                Write-Log "  Could not save attachment '$filename': $_"
                $allMatched = $false
                $reviewNotes += "Could not save attachment '$filename': $_"
                continue
            }

            # Step 1: ID in attachment filename, then in email subject
            $memberId = Get-MemberIdFromText $members $filename
            if (-not $memberId) { $memberId = Get-MemberIdFromText $members $subject }
            $member   = if ($memberId) { Find-MemberById $members $memberId } else { $null }
            $docType  = Get-DocTypeFromFilename $filename
            $ocrText  = ''
            $via      = 'filename/subject'

            # Step 2: OCR fallback
            if (-not $member) {
                Write-Log "  No member ID in filename/subject --- running OCR on '$filename'..."
                try {
                    $ocrText = Get-OcrText $stagedPath
                    if ($ocrText) {
                        $ocrDocType = Get-DocTypeFromOcrText $ocrText
                        if ($ocrDocType) { $docType = $ocrDocType }
                        $match = Find-MemberInOcrText $ocrText $members
                        if ($match) {
                            $member   = $match.member
                            $memberId = Get-PropValue $member @('ID','id','MEMBER ID')
                            $via      = "OCR: $($match.via) [$($match.confidence) confidence]"
                            if ($match.confidence -eq 'low') { Write-Log "  LOW CONFIDENCE match --- please verify in file cabinet." }
                        }
                    } else {
                        Write-Log "  OCR returned no text."
                    }
                } catch {
                    Write-Log "  OCR ERROR: $_"
                }
            }

            if ($member) {
                $mName = Get-MemberName $member
                Write-Log "  Member  : $mName (ID: $memberId)"
                Write-Log "  Doc Type: $docType"
                Write-Log "  Via     : $via"
                try {
                    Upload-File $stagedPath $memberId $mName $docType | Out-Null
                    Write-Log "  SUCCESS: Uploaded to $mName's file cabinet."
                    try {
                        $dest = Copy-ToMemberFolder $stagedPath $filename $member $memberId
                        Write-Log "  SAVED  : $dest"
                    } catch {
                        Write-Log "  Could not save local copy: $_"
                    }
                } catch {
                    Write-Log "  UPLOAD FAILED: $_"
                    $allMatched = $false
                    $reviewNotes += "Upload failed for '$filename': $_"
                }
            } else {
                Write-Log "  Could not identify member for '$filename'."
                $allMatched = $false
                $reviewNotes += "Could not identify member for '$filename'." + $(if ($ocrText) { "`r`n--- OCR TEXT ---`r`n$ocrText" } else { " (no OCR text read)" })
            }

            Remove-Item $stagedPath -Force -ErrorAction SilentlyContinue
        }

        if ($allMatched) {
            Write-Log "  All attachments processed --- moved to Processed."
            try { $mail.Move($processedFolder) | Out-Null } catch { Write-Log "  Could not move email: $_" }
        } else {
            Write-Log "  One or more attachments need manual review --- moved to Review."
            try {
                if ($reviewNotes.Count -gt 0) {
                    $notePath = Join-Path $StagingDir "$(Get-Random)_review-notes.txt"
                    $reviewNotes -join "`r`n`r`n" | Out-File $notePath -Encoding UTF8
                    $mail.Attachments.Add($notePath, 1, $null, "review-notes.txt") | Out-Null
                    $mail.Save()
                    Remove-Item $notePath -Force -ErrorAction SilentlyContinue
                }
                $mail.Move($reviewFolder) | Out-Null
            } catch {
                Write-Log "  Could not move email to Review: $_"
            }
        }
    }

    Start-Sleep -Seconds $POLL_SECONDS
}
