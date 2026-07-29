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
    
    # Try to write to log file, but don't spam console if it fails
    # (likely locked by OneDrive or another instance)
    try {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Fail silently
    }
}

# ------ Check if file is ready to process (not locked by scanner/OneDrive) -----------------
function Test-FileReady {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $false
    }
    
    try {
        $stream = [System.IO.File]::Open($FilePath, 'Open', 'Read', 'None')
        $stream.Close()
        return $true
    } catch {
        return $false
    }
}

# ------ WinRT async helper ------------------------------------------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null

function Await {
    param($WinRtTask)
    
    try {
        # Poll the Status property until completion
        # Status values: 0=Started, 1=Completed, 2=Canceled, 3=Error
        $timeout = 30000  # 30 seconds in milliseconds
        $waited = 0
        
        while ($WinRtTask.Status -eq 0 -and $waited -lt $timeout) {
            Start-Sleep -Milliseconds 100
            $waited += 100
        }
        
        if ($waited -ge $timeout) {
            throw "WinRT async operation timed out after 30 seconds"
        }
        
        # Check final status
        if ($WinRtTask.Status -eq 3) {
            throw "WinRT async operation failed"
        }
        if ($WinRtTask.Status -eq 2) {
            throw "WinRT async operation was canceled"
        }
        
        # Try to get results
        try {
            return $WinRtTask.GetResults()
        } catch {
            # Some operations (IAsyncAction) don't return results
            return $null
        }
        
    } catch {
        Write-Log "  Await error: $($_.Exception.Message)"
        throw
    }
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
        # Copy PDF to temp location to avoid OneDrive/long path issues with WinRT
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
        
        # Clean up temp PDF
        Remove-Item $tempPdf -Force -ErrorAction SilentlyContinue
        
        return $tmpPng
    } catch {
        Write-Log "  OCR: PDF render failed: $_"
        return $null
    }
}

# ------ OCR: read text from an image file ------------------------------------------------------------------------
function Get-OcrTextFromImage($imagePath) {
    try {
        # Copy to temp location to avoid OneDrive path issues
        $ext = [System.IO.Path]::GetExtension($imagePath)
        $tempImage = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "ocr_img_$(Get-Random)$ext")
        Copy-Item -Path $imagePath -Destination $tempImage -Force
        
        $engine  = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
        if (-not $engine) { 
            Write-Log "  OCR engine initialization failed - Windows OCR not available"
            Write-Log "  Install a language pack from Windows Settings > Time & Language > Language"
            Remove-Item $tempImage -Force -ErrorAction SilentlyContinue
            return '' 
        }

        $sf      = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($tempImage))
        $stream  = Await ($sf.OpenAsync([Windows.Storage.FileAccessMode]::Read))
        $decoder = Await ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream))
        $bitmap  = Await ($decoder.GetSoftwareBitmapAsync())
        $result  = Await ($engine.RecognizeAsync($bitmap))
        $stream.Dispose()
        
        # Clean up temp file
        Remove-Item $tempImage -Force -ErrorAction SilentlyContinue
        
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
        $fn = (Get-PropValue $m @('FIRST','first','FIRST NAME','FIRST\r\nNAME','FIRST\nNAME','firstName')).ToLower().Trim()
        $ln = (Get-PropValue $m @('LAST','last','LAST NAME','LAST\r\nNAME','LAST\nNAME','lastName')).ToLower().Trim()
        if ($fn.Length -lt 2 -or $ln.Length -lt 2) { continue }
        if ($text -match [regex]::Escape($fn) -and $text -match [regex]::Escape($ln)) {
            return @{ member=$m; confidence='high'; via="full name ($fn $ln)" }
        }
    }
    # 3. Last name only (lower confidence)
    foreach ($m in $members) {
        $ln = (Get-PropValue $m @('LAST','last','LAST NAME','LAST\r\nNAME','LAST\nNAME','lastName')).ToLower().Trim()
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
    $f = Get-PropValue $m @('FIRST','first','FIRST NAME','FIRST`r`nNAME','FIRST`nNAME','firstName')
    $l = Get-PropValue $m @('LAST','last','LAST NAME','LAST`r`nNAME','LAST`nNAME','lastName')
    return "$f $l".Trim()
}
function Get-Members {
    try { 
        Write-Log "  Fetching members from API: $API_BASE/members"
        $all = Invoke-RestMethod -Uri "$API_BASE/members" -Method GET -TimeoutSec 15
        
        if (-not $all) {
            Write-Log "  WARNING: API returned null/empty"
            return $null
        }
        
        Write-Log "  Total members from API: $($all.Count)"
        
        # For document inbox, we want ALL members (active, alumni, discharged, etc.)
        # Someone might scan a document for any member regardless of status
        if ($all.Count -gt 0) {
            # Show status breakdown for debugging
            $statusGroups = $all | Group-Object { (Get-PropValue $_ @('STATUS','STATU','status')).Trim() }
            foreach ($g in $statusGroups) {
                Write-Log "    Status '$($g.Name)': $($g.Count) members"
            }
        }
        
        return $all
    }
    catch { 
        Write-Log "ERROR fetching members: $($_.Exception.Message)"
        Write-Log "  Stack: $($_.ScriptStackTrace)"
        return $null 
    }
}

# ------ Filename-based helpers ------------------------------------------------------------------------------------------------------------
function Get-MemberIdFromFilename($members, $filename) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($filename).ToLower()
    
    # Try multiple patterns for member ID (support 2-9 digit IDs)
    # Pattern 1: "ID 123" or "member ID 123" or "memberid123"
    if ($base -match '(?:member\s*)?id[\s:-]*?(\d{2,9})\b') {
        $candidateId = $matches[1]
        Write-Log "  Found ID pattern in filename: $candidateId"
        return $candidateId
    }
    
    # Pattern 2: Just digits at start "174.pdf" or "170-document.pdf" or "145045_file.pdf"
    if ($base -match '^(\d{2,9})(?:\D|$)') {
        $candidateId = $matches[1]
        Write-Log "  Found ID at start of filename: $candidateId"
        return $candidateId
    }
    
    # Pattern 3: Any 2-9 digit number as word boundary
    $nums = [regex]::Matches($base, '\b(\d{2,9})\b')
    if ($nums.Count -gt 0) {
        # Try to match against known members first
        foreach ($n in $nums) { 
            if (Find-MemberById $members $n.Groups[1].Value) { 
                Write-Log "  Matched known member ID from filename: $($n.Groups[1].Value)"
                return $n.Groups[1].Value 
            } 
        }
        # If no known match, return first number found
        Write-Log "  Using first number found in filename: $($nums[0].Groups[1].Value)"
        return $nums[0].Groups[1].Value
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
        if ($null -ne $members -and $members.Count -gt 0) { 
            $lastMemberLoad = [datetime]::Now
            Write-Log "Loaded $($members.Count) members."
        }
        elseif ($null -eq $members) { 
            Write-Log "Cannot reach server --- retrying in $POLL_SECONDS s."
            Start-Sleep -Seconds $POLL_SECONDS
            continue 
        }
        else {
            Write-Log "WARNING: Server returned 0 members. Retrying in $POLL_SECONDS s."
            Start-Sleep -Seconds $POLL_SECONDS
            continue
        }
    }

    $files = Get-ChildItem -Path $INBOX_FOLDER -File -ErrorAction SilentlyContinue |
             Where-Object { $_.DirectoryName -eq $INBOX_FOLDER -and $_.Extension -notin @('.bat','.txt','.log') }

    foreach ($file in $files) {
        $filename = $file.Name
        
        # Wait for file to be fully written and not locked (by scanner or OneDrive sync)
        $maxWait = 10  # seconds
        $waited = 0
        while ($waited -lt $maxWait) {
            if (Test-FileReady $file.FullName) {
                break
            }
            Start-Sleep -Milliseconds 500
            $waited += 0.5
            # Refresh file object in case it was moved/deleted
            if (-not (Test-Path $file.FullName)) {
                Write-Log "File disappeared (likely OneDrive sync): $filename"
                continue
            }
        }
        
        # Final check - if still not ready or doesn't exist, skip it
        if (-not (Test-Path $file.FullName)) {
            Write-Log "File no longer exists: $filename - skipping"
            continue
        }
        
        if (-not (Test-FileReady $file.FullName)) {
            Write-Log "File still locked after ${maxWait}s wait: $filename - skipping this cycle"
            continue
        }

        Write-Log "------------------------------------------------------------------------------"
        Write-Log "File: $filename"

        # Step 1: filename-based detection
        $memberId = Get-MemberIdFromFilename $members $filename
        $member   = if ($memberId) { Find-MemberById $members $memberId } else { $null }
        
        if ($memberId -and -not $member) {
            Write-Log "  Found ID $memberId in filename, but member not in active list (may be alumni/discharged)"
            Write-Log "  Attempting to use ID anyway..."
            # Try to get member details directly from API
            try {
                $memberDirect = Invoke-RestMethod -Uri "$API_BASE/getMember?id=$memberId" -Method GET -TimeoutSec 10 -ErrorAction Stop
                if ($memberDirect) {
                    $member = $memberDirect
                    Write-Log "  Retrieved member from API: $(Get-MemberName $member)"
                }
            } catch {
                Write-Log "  Could not retrieve member $memberId from API: $_"
            }
        }
        
        $docType  = Get-DocTypeFromFilename $filename
        $ocrText  = ''
        $via      = 'filename'

        # Step 2: OCR if filename gave no match
        if (-not $member) {
            # Check if file still exists before OCR
            if (-not (Test-Path $file.FullName)) {
                Write-Log "  File disappeared before OCR - skipping"
                continue
            }
            
            Write-Log "  No member ID in filename --- running OCR..."
            try {
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
            } catch {
                Write-Log "  OCR ERROR: $_"
                Write-Log "  Moving to review folder for manual processing"
                if (Test-Path $file.FullName) {
                    $reviewDest = Join-Path $ReviewDir $filename
                    if (Test-Path $reviewDest) { 
                        $reviewDest = Join-Path $ReviewDir ("$(Get-Date -Format 'HHmmss')_$filename") 
                    }
                    try {
                        Move-Item -Path $file.FullName -Destination $reviewDest -Force -ErrorAction Stop
                    } catch {
                        Write-Log "  Could not move file (may have been moved by OneDrive): $_"
                    }
                }
                continue
            }
        }

        # Step 3: upload or send to review
        if ($member) {
            # Check if file still exists before upload
            if (-not (Test-Path $file.FullName)) {
                Write-Log "  File disappeared before upload - skipping"
                continue
            }
            
            $mName = Get-MemberName $member
            Write-Log "  Member  : $mName (ID: $memberId)"
            Write-Log "  Doc Type: $docType"
            Write-Log "  Via     : $via"
            try {
                Upload-File $file.FullName $memberId $mName $docType | Out-Null
                Write-Log "  SUCCESS: Uploaded to $mName's file cabinet."
                
                # Move to processed folder if file still exists
                if (Test-Path $file.FullName) {
                    $dest = Join-Path $ProcessedDir $filename
                    if (Test-Path $dest) { 
                        $dest = Join-Path $ProcessedDir ("$(Get-Date -Format 'HHmmss')_$filename") 
                    }
                    try {
                        Move-Item -Path $file.FullName -Destination $dest -Force -ErrorAction Stop
                    } catch {
                        Write-Log "  Could not move to processed folder (may have been moved by OneDrive): $_"
                    }
                } else {
                    Write-Log "  File was already moved/deleted (likely by OneDrive)"
                }
            } catch {
                Write-Log "  UPLOAD FAILED: $_"
                if (Test-Path $file.FullName) {
                    $reviewDest = Join-Path $ReviewDir $filename
                    if (Test-Path $reviewDest) { 
                        $reviewDest = Join-Path $ReviewDir ("$(Get-Date -Format 'HHmmss')_$filename") 
                    }
                    try {
                        Move-Item -Path $file.FullName -Destination $reviewDest -Force -ErrorAction Stop
                        if ($ocrText) { 
                            $ocrText | Out-File (Join-Path $ReviewDir "$filename.ocr.txt") -Encoding UTF8 
                        }
                    } catch {
                        Write-Log "  Could not move to review folder: $_"
                    }
                } else {
                    Write-Log "  File disappeared during upload failure handling"
                }
            }
        } else {
            Write-Log "  Could not identify member --- moved to review folder."
            if (Test-Path $file.FullName) {
                $reviewDest = Join-Path $ReviewDir $filename
                if (Test-Path $reviewDest) { 
                    $reviewDest = Join-Path $ReviewDir ("$(Get-Date -Format 'HHmmss')_$filename") 
                }
                try {
                    Move-Item -Path $file.FullName -Destination $reviewDest -Force -ErrorAction Stop
                    if ($ocrText) { 
                        $ocrText | Out-File (Join-Path $ReviewDir "$filename.ocr.txt") -Encoding UTF8 
                    }
                } catch {
                    Write-Log "  Could not move to review folder: $_"
                }
            } else {
                Write-Log "  File disappeared before moving to review"
            }
        }
    }

    Start-Sleep -Seconds $POLL_SECONDS
}


