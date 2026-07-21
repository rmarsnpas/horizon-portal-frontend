# ============================================================
# Horizon House – Document Inbox Watcher
# ============================================================
# Watches a local folder. Any file named with a member ID
# (e.g. "0133_letter.pdf" or "160 Darren agreement.pdf")
# is automatically uploaded to the portal file cabinet.
#
# HOW TO USE:
#   1. Set INBOX_FOLDER below to the folder your scanner saves to
#      (or any OneDrive folder you want to use as the inbox).
#   2. Name your files with the member ID anywhere in the filename.
#   3. Run this script. Leave it running in the background.
#   4. Drop files into the inbox folder — they upload automatically.
#
# Processed files move to: <INBOX_FOLDER>\processed\
# Failed files move to:    <INBOX_FOLDER>\failed\
# ============================================================

# ── Configuration ────────────────────────────────────────────
$INBOX_FOLDER = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\Members\_inbox"
$API_BASE     = "https://horizon-portal-backend-production-3532.up.railway.app/api"
$STAFF_ID     = ""   # Fill in your staff member ID (e.g. "0005")
$STAFF_PW     = ""   # Fill in your staff password
$DEFAULT_TYPE = "General"   # Default doc type if not detected from filename
$POLL_SECONDS = 10          # How often to check the folder (seconds)
# ─────────────────────────────────────────────────────────────

$ProcessedDir = Join-Path $INBOX_FOLDER "processed"
$FailedDir    = Join-Path $INBOX_FOLDER "failed"
$LogFile      = Join-Path $INBOX_FOLDER "upload-log.txt"

# Create inbox and subfolders if they don't exist
@($INBOX_FOLDER, $ProcessedDir, $FailedDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

function Write-Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

# ── Load members from API ─────────────────────────────────────
function Get-Members {
    try {
        $resp = Invoke-RestMethod -Uri "$API_BASE/members" -Method GET -TimeoutSec 15
        return $resp
    } catch {
        Write-Log "ERROR: Could not fetch member list: $_"
        return $null
    }
}

function Find-MemberById($members, $rawId) {
    $id = $rawId.TrimStart('0')
    foreach ($m in $members) {
        $mid = (($m.ID ?? $m.id ?? $m.'MEMBER ID') + '') .TrimStart('0')
        if ($mid -eq $id) { return $m }
    }
    return $null
}

function Get-MemberName($m) {
    $f = $m.FIRST ?? $m.first ?? $m.'FIRST NAME' ?? ''
    $l = $m.LAST  ?? $m.last  ?? $m.'LAST NAME'  ?? ''
    return "$f $l".Trim()
}

# ── Parse member ID from filename ────────────────────────────
function Get-MemberIdFromFilename($members, $filename) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    $matches = [regex]::Matches($base, '\b(\d{2,4})\b')
    foreach ($match in $matches) {
        $candidate = $match.Groups[1].Value
        $m = Find-MemberById $members $candidate
        if ($m) { return $candidate }
    }
    # Fall back to first numeric match
    if ($matches.Count -gt 0) { return $matches[0].Groups[1].Value }
    return $null
}

# ── Guess doc type from filename ─────────────────────────────
function Get-DocType($filename) {
    $lower = $filename.ToLower()
    if ($lower -match 'agree|agreement|contract')      { return 'Agreement' }
    if ($lower -match 'letter|ltr')                    { return 'Letter' }
    if ($lower -match 'roi|release')                   { return 'Release of Information' }
    if ($lower -match 'drug.?screen|ua\b|urinalysis')  { return 'Drug Screen' }
    if ($lower -match 'incident|report')               { return 'Incident Report' }
    if ($lower -match '\bid\b|license|passport')       { return 'ID / License' }
    if ($lower -match 'insurance|card')                { return 'Insurance Card' }
    if ($lower -match 'cam|footage|\.mp4|\.mov|\.avi') { return 'Camera Footage' }
    if ($lower -match 'court|probation|parole')        { return 'Court Document' }
    if ($lower -match 'property|storage')              { return 'Property Form' }
    if ($lower -match 'application|app\b')             { return 'Application' }
    if ($lower -match 'medical|med\b|rx|prescription') { return 'Medical Record' }
    return $DEFAULT_TYPE
}

# ── Upload a single file ──────────────────────────────────────
function Upload-File($filePath, $memberId, $memberName, $docType) {
    $filename    = [System.IO.Path]::GetFileName($filePath)
    $contentType = switch -Regex ($filename.ToLower()) {
        '\.pdf$'              { 'application/pdf' }
        '\.(jpg|jpeg)$'       { 'image/jpeg' }
        '\.png$'              { 'image/png' }
        '\.(mp4|m4v)$'        { 'video/mp4' }
        '\.mov$'              { 'video/quicktime' }
        '\.(doc|docx)$'       { 'application/msword' }
        default               { 'application/octet-stream' }
    }

    $boundary = [System.Guid]::NewGuid().ToString()
    $LF = "`r`n"
    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)

    $bodyParts = @()
    foreach ($field in @(
        @{ name='memberId';    value=$memberId   },
        @{ name='memberName';  value=$memberName },
        @{ name='docType';     value=$docType    },
        @{ name='notes';       value=$filename   }
    )) {
        $bodyParts += "--$boundary$LF"
        $bodyParts += "Content-Disposition: form-data; name=`"$($field.name)`"$LF$LF"
        $bodyParts += "$($field.value)$LF"
    }

    $encoding = [System.Text.Encoding]::UTF8
    $preFileBytes = $encoding.GetBytes(
        ($bodyParts -join '') +
        "--$boundary$LF" +
        "Content-Disposition: form-data; name=`"document`"; filename=`"$filename`"$LF" +
        "Content-Type: $contentType$LF$LF"
    )
    $postFileBytes = $encoding.GetBytes("$LF--$boundary--$LF")

    $bodyBytes = New-Object byte[] ($preFileBytes.Length + $fileBytes.Length + $postFileBytes.Length)
    [System.Buffer]::BlockCopy($preFileBytes,  0, $bodyBytes, 0, $preFileBytes.Length)
    [System.Buffer]::BlockCopy($fileBytes,     0, $bodyBytes, $preFileBytes.Length, $fileBytes.Length)
    [System.Buffer]::BlockCopy($postFileBytes, 0, $bodyBytes, $preFileBytes.Length + $fileBytes.Length, $postFileBytes.Length)

    $response = Invoke-RestMethod `
        -Uri "$API_BASE/member-documents/upload" `
        -Method POST `
        -ContentType "multipart/form-data; boundary=$boundary" `
        -Body $bodyBytes `
        -TimeoutSec 60

    return $response
}

# ── Main loop ─────────────────────────────────────────────────
Write-Log "=== Document Inbox Watcher started ==="
Write-Log "Watching: $INBOX_FOLDER"
Write-Log "Processed files go to: $ProcessedDir"
Write-Log "Failed files go to:    $FailedDir"
Write-Log "Press Ctrl+C to stop."
Write-Log ""

# Load members once at startup (refresh hourly)
$members      = $null
$lastMemberLoad = [datetime]::MinValue

while ($true) {
    # Refresh member list hourly
    if (-not $members -or ([datetime]::Now - $lastMemberLoad).TotalHours -gt 1) {
        Write-Log "Loading member list from API..."
        $members = Get-Members
        if ($members) {
            $lastMemberLoad = [datetime]::Now
            Write-Log "Loaded $($members.Count) members."
        } else {
            Write-Log "WARNING: Could not load members. Will retry next cycle."
            Start-Sleep -Seconds $POLL_SECONDS
            continue
        }
    }

    # Get all non-directory files directly in inbox (not subfolders)
    $files = Get-ChildItem -Path $INBOX_FOLDER -File -ErrorAction SilentlyContinue |
             Where-Object { $_.DirectoryName -eq $INBOX_FOLDER }

    foreach ($file in $files) {
        # Wait briefly to make sure file is fully written (scanner may still be writing)
        Start-Sleep -Milliseconds 800

        $filename = $file.Name
        Write-Log "Found file: $filename"

        # Parse member ID
        $memberId = Get-MemberIdFromFilename $members $filename
        if (-not $memberId) {
            Write-Log "  WARNING: No member ID found in filename '$filename'. Moving to failed."
            Move-Item -Path $file.FullName -Destination (Join-Path $FailedDir $filename) -Force
            continue
        }

        $member = Find-MemberById $members $memberId
        if (-not $member) {
            Write-Log "  WARNING: Member ID '$memberId' not found. Moving to failed."
            Move-Item -Path $file.FullName -Destination (Join-Path $FailedDir $filename) -Force
            continue
        }

        $mName  = Get-MemberName $member
        $docType = Get-DocType $filename
        Write-Log "  → Member: $mName (ID: $memberId) | Type: $docType"

        try {
            $result = Upload-File $file.FullName $memberId $mName $docType
            Write-Log "  ✅ Uploaded successfully. Doc ID: $($result.entry.id ?? 'ok')"
            $destName = $filename  # keep original name
            Move-Item -Path $file.FullName -Destination (Join-Path $ProcessedDir $destName) -Force
        } catch {
            Write-Log "  ❌ Upload failed: $_"
            Move-Item -Path $file.FullName -Destination (Join-Path $FailedDir $filename) -Force
        }
    }

    Start-Sleep -Seconds $POLL_SECONDS
}
