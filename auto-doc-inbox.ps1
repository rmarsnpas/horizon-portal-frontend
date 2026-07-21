# ============================================================
# Horizon House --- Document Inbox Watcher  (with OCR)
# ============================================================
# Just scan and walk away. Drop any file into the inbox folder
# and this script will:
#   1. Try to find the member ID from the filename
#   2. If no ID in filename, run OCR on the document to read
#      member names and IDs directly from the page content
#   3. Auto-detect the document type (Drug Screen, Agreement, etc.)
#   4. Upload to the correct member's file cabinet
#   5. Move unidentified files to a "review" folder with the
#      OCR text saved alongside so you can easily assign manually
#
# Processed files --- _inbox\processed\
# Unidentified    --- _inbox\review\   (with .ocr.txt companion)
# ============================================================

# ------ Configuration ------------------------------------------------------------------------------------------------------------------------------------
$INBOX_FOLDER = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\Members\_inbox"
$API_BASE     = "https://horizon-portal-backend-production-3532.up.railway.app/api"
$DEFAULT_TYPE = "General"
$POLL_SECONDS = 10
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$ProcessedDir = Join-Path $INBOX_FOLDER "processed"
$ReviewDir    = Join-Path $INBOX_FOLDER "review"
$LogFile      = Join-Path $INBOX_FOLDER "upload-log.txt"

@($INBOX_FOLDER, $ProcessedDir, $ReviewDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

function Write-Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

# ------ WinRT async helper ------------------------------------------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null
$script:_asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
                   $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

function Await {
    param($WinRtTask, [Type]$ResultType = $null)
    if ($null -ne $ResultType) {
        $task = $script:_asTaskGeneric.MakeGenericMethod($ResultType).Invoke($null, @($WinRtTask))
    } else {
        $task = [System.WindowsRuntimeSystemExtensions]::AsTask($WinRtTask)
    }
    $task.Wait(-1) | Out-Null
    if ($null -ne $ResultType) { return $task.Result }
}

# ------ Load WinRT types ------------------------------------------------------------------------------------------------------------------------------
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
        Write-Log "         OCR disabled. Files must be named with member IDs."
        return $false
    }
}

# ------ Render first page of PDF to a temp PNG ---------------------------------------------------------
function Render-PdfFirstPage($pdfPath) {
    try {
        $tmpPng  = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.png')
        $absPath = (Resolve-Path $pdfPath).Path

        $sf    = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($absPath)) ([Windows.Storage.StorageFile])
        $pdf   = Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($sf)) ([Windows.Data.Pdf.PdfDocument])
        if ($pdf.PageCount -eq 0) { return $null }
        $page  = $pdf.GetPage(0)

        $tmpDir  = [System.IO.Path]::GetDirectoryName($tmpPng)
        $tmpName = [System.IO.Path]::GetFileName($tmpPng)
        $folder  = Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($tmpDir)) ([Windows.Storage.StorageFolder])
        $outFile = Await ($folder.CreateFileAsync($tmpName, [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
        $stream  = Await ($outFile.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite)) ([Windows.Storage.Streams.IRandomAccessStream])

        $opts = New-Object Windows.Data.Pdf.PdfPageRenderOptions
        $opts.DestinationHeight = 2400
        Await ($page.RenderToStreamAsync($stream, $opts)) $null
        $stream.Dispose()
        $page.Dispose()
        return $tmpPng
    } catch {
        Write-Log "  OCR: PDF render failed: $_"
        return $null
    }
}

# ------ OCR: read text from an image file ------------------------------------------------------------------------
function Get-OcrTextFromImage($imagePath) {
    try {
        $absPath = (Resolve-Path $imagePath).Path
        $engine  = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
        if (-not $engine) { return '' }

        $sf      = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($absPath)) ([Windows.Storage.StorageFile])
        $stream  = Await ($sf.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
        $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
        $bitmap  = Await ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
        $result  = Await ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
        $stream.Dispose()
        return $result.Text
    } catch {
        Write-Log "  OCR: Image read failed: $_"
        return ''
    }
}

# ------ OCR dispatcher ------------------------------------------------------------------------------------------------------------------------------------
function Get-OcrText($filePath) {
    if (-not $script:_ocrEnabled) { return '' }
    $ext    = [System.IO.Path]::GetExtension($filePath).ToLower()
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

# ------ Find member in OCR text ---------------------------------------------------------------------------------------------------------
function Find-MemberInOcrText($ocrText, $members) {
    if (-not $ocrText) { return $null }
    $text = $ocrText.ToLower()

    # 1. Known member IDs (digit sequences)
    foreach ($dm in [regex]::Matches($ocrText, '\b(\d{2,4})\b')) {
        $m = Find-MemberById $members $dm.Groups[1].Value
        if ($m) { return @{ member=$m; confidence='high'; via="ID $($dm.Groups[1].Value)" } }
    }
    # 2. Full name (first + last both present)
    foreach ($m in $members) {
        $fn = (Get-PropValue $m @('FIRST','first','FIRST NAME')).ToLower().Trim()
        $ln = (Get-PropValue $m @('LAST','last','LAST NAME')).ToLower().Trim()
        if ($fn.Length -lt 2 -or $ln.Length -lt 2) { continue }
        if ($text -match [regex]::Escape($fn) -and $text -match [regex]::Escape($ln)) {
            return @{ member=$m; confidence='high'; via="full name ($fn $ln)" }
        }
    }
    # 3. Last name only (lower confidence)
    foreach ($m in $members) {
        $ln = (Get-PropValue $m @('LAST','last','LAST NAME')).ToLower().Trim()
        if ($ln.Length -lt 3) { continue }
        if ($text -match "\b$([regex]::Escape($ln))\b") {
            return @{ member=$m; confidence='low'; via="last name only ($ln)" }
        }
    }
    return $null
}

# ------ Detect document type from OCR text ---------------------------------------------------------------------
function Get-DocTypeFromOcrText($ocrText) {
    if (-not $ocrText) { return $null }
    $t = $ocrText.ToLower()
    if ($t -match 'drug screen|urinalysis|\bua\b|urine|drug test')        { return 'Drug Screen' }
    if ($t -match 'incident report|incident\s+#|incident form')           { return 'Incident Report' }
    if ($t -match 'release of information|release.*information')          { return 'Release of Information' }
    if ($t -match 'member agreement|resident agreement|house rules')      { return 'Agreement' }
    if ($t -match 'emergency contact')                                    { return 'Emergency Contact Form' }
    if ($t -match 'court|probation|parole|case.*number|docket')          { return 'Court Document' }
    if ($t -match 'insurance|medi-?cal|medicaid|medicare|health.*plan')  { return 'Insurance Card' }
    if ($t -match 'application for (residency|admission|housing)')       { return 'Application' }
    if ($t -match 'prescription|\brx\b|medication list')                 { return 'Medical Record' }
    if ($t -match 'property|belongings|storage|inventory')               { return 'Property Form' }
    if ($t -match "driver.?s license|state id|identification card")      { return 'ID / License' }
    return $null
}

# ------ Member helpers ------------------------------------------------------------------------------------------------------------------------------------
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
    $f = Get-PropValue $m @('FIRST','first','FIRST NAME')
    $l = Get-PropValue $m @('LAST','last','LAST NAME')
    return "$f $l".Trim()
}
function Get-Members {
    try { return Invoke-RestMethod -Uri "$API_BASE/members" -Method GET -TimeoutSec 15 }
    catch { Write-Log "ERROR fetching members: $_"; return $null }
}

# ------ Filename-based helpers ------------------------------------------------------------------------------------------------------------
function Get-MemberIdFromFilename($members, $filename) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $nums = [regex]::Matches($base, '\b(\d{2,4})\b')
    foreach ($n in $nums) { if (Find-MemberById $members $n.Groups[1].Value) { return $n.Groups[1].Value } }
    if ($nums.Count -gt 0) { return $nums[0].Groups[1].Value }
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

# ------ Upload file to portal ---------------------------------------------------------------------------------------------------------------
function Upload-File($filePath, $memberId, $memberName, $docType) {
    $filename    = [System.IO.Path]::GetFileName($filePath)
    $contentType = switch -Regex ($filename.ToLower()) {
        '\.pdf$'        { 'application/pdf' }
        '\.(jpg|jpeg)$' { 'image/jpeg' }
        '\.png$'        { 'image/png' }
        '\.(mp4|m4v)$'  { 'video/mp4' }
        '\.mov$'        { 'video/quicktime' }
        '\.(doc|docx)$' { 'application/msword' }
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

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Write-Log "=== Horizon House Document Inbox Watcher ==="
Write-Log "Watching : $INBOX_FOLDER"
Write-Log "Processed: $ProcessedDir"
Write-Log "Review   : $ReviewDir"
Write-Log "Press Ctrl+C to stop."
Write-Log ""

$script:_ocrEnabled = Load-WinRTTypes
Write-Log $(if ($script:_ocrEnabled) { "OCR: ENABLED -- will read document content to identify members." } else { "OCR: DISABLED --- files must be named with member IDs." })
Write-Log ""

$members        = $null
$lastMemberLoad = [datetime]::MinValue

while ($true) {
    if (-not $members -or ([datetime]::Now - $lastMemberLoad).TotalHours -gt 1) {
        Write-Log "Loading member list..."
        $members = Get-Members
        if ($members) { $lastMemberLoad = [datetime]::Now; Write-Log "Loaded $($members.Count) members." }
        else { Write-Log "Cannot reach server --- retrying in $POLL_SECONDS s."; Start-Sleep -Seconds $POLL_SECONDS; continue }
    }

    $files = Get-ChildItem -Path $INBOX_FOLDER -File -ErrorAction SilentlyContinue |
             Where-Object { $_.DirectoryName -eq $INBOX_FOLDER -and $_.Extension -notin @('.bat','.txt','.log') }

    foreach ($file in $files) {
        Start-Sleep -Milliseconds 1200   # let scanner finish writing

        $filename = $file.Name
        Write-Log "------------------------------------------------------------------------------"
        Write-Log "File: $filename"

        # Step 1: filename-based detection
        $memberId = Get-MemberIdFromFilename $members $filename
        $member   = if ($memberId) { Find-MemberById $members $memberId } else { $null }
        $docType  = Get-DocTypeFromFilename $filename
        $ocrText  = ''
        $via      = 'filename'

        # Step 2: OCR if filename gave no match
        if (-not $member) {
            Write-Log "  No member ID in filename --- running OCR..."
            $ocrText = Get-OcrText $file.FullName

            if ($ocrText) {
                Write-Log "  OCR read $(($ocrText -split '\s+').Count) words."
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
        }

        # Step 3: upload or send to review
        if ($member) {
            $mName = Get-MemberName $member
            Write-Log "  Member  : $mName (ID: $memberId)"
            Write-Log "  Doc Type: $docType"
            Write-Log "  Via     : $via"
            try {
                Upload-File $file.FullName $memberId $mName $docType | Out-Null
                Write-Log "  SUCCESS: Uploaded to $mName's file cabinet."
                $dest = Join-Path $ProcessedDir $filename
                if (Test-Path $dest) { $dest = Join-Path $ProcessedDir ("$(Get-Date -Format 'HHmmss')_$filename") }
                Move-Item -Path $file.FullName -Destination $dest -Force
            } catch {
                Write-Log "  UPLOAD FAILED: $_"
                Move-Item -Path $file.FullName -Destination (Join-Path $ReviewDir $filename) -Force
                if ($ocrText) { $ocrText | Out-File (Join-Path $ReviewDir "$filename.ocr.txt") -Encoding UTF8 }
            }
        } else {
            Write-Log "  Could not identify member --- moved to review folder."
            Move-Item -Path $file.FullName -Destination (Join-Path $ReviewDir $filename) -Force
            if ($ocrText) {
                $ocrText | Out-File (Join-Path $ReviewDir "$filename.ocr.txt") -Encoding UTF8
                Write-Log "  OCR text saved as $filename.ocr.txt --- open it to see what was read."
            }
            Write-Log "  To fix: rename with member ID and drop back in inbox."
        }
    }

    Start-Sleep -Seconds $POLL_SECONDS
}


