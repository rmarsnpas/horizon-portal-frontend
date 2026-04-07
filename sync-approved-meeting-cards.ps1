# sync-approved-meeting-cards.ps1
# Downloads approved meeting card images and saves to OneDrive by member name.
# Run manually or schedule as a Windows Task.

$API_BASE  = "https://horizon-portal-backend-production-3532.up.railway.app"
$SAVE_ROOT = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\Meeting Cards"

Write-Host "Syncing approved meeting cards to OneDrive..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "$API_BASE/api/meetingCards" -Method GET -TimeoutSec 30
    $cards = $response.cards
} catch {
    Write-Host "ERROR: Could not reach API - $_" -ForegroundColor Red
    exit 1
}

$approved = $cards | Where-Object { $_.status -eq "approved" }
Write-Host "  Found $($approved.Count) approved card(s)." -ForegroundColor Green

$synced  = 0
$skipped = 0
$errors  = 0

foreach ($card in $approved) {
    $rawName   = if ($card.memberName) { $card.memberName } else { "Member_$($card.memberId)" }
    $safeName  = $rawName -replace '[\\/:*?<>|]', '_'
    $memberDir = Join-Path $SAVE_ROOT $safeName

    if (-not (Test-Path $memberDir)) {
        New-Item -ItemType Directory -Path $memberDir -Force | Out-Null
    }

    if ($card.imageUrl -match '^https?://') {
        $imgUrl = $card.imageUrl
    } else {
        $imgUrl = "$API_BASE$($card.imageUrl)"
    }

    $ext = [System.IO.Path]::GetExtension($imgUrl.Split('?')[0])
    if (-not $ext) { $ext = ".jpg" }

    $weekStr  = if ($card.meetingDate) { $card.meetingDate -replace '-', '' } else { "nodate" }
    $fileName = "MeetingCard_${weekStr}_$($card.id)${ext}"
    $destPath = Join-Path $memberDir $fileName

    if (Test-Path $destPath) {
        $skipped++
        continue
    }

    try {
        Invoke-WebRequest -Uri $imgUrl -OutFile $destPath -TimeoutSec 30 -UseBasicParsing
        Write-Host "  OK  $safeName\$fileName" -ForegroundColor Green
        $synced++
    } catch {
        Write-Host "  ERR $imgUrl - $_" -ForegroundColor Yellow
        $errors++
    }
}

Write-Host ""
Write-Host "Done. Synced: $synced  |  Already saved: $skipped  |  Errors: $errors" -ForegroundColor Cyan
Write-Host "Folder: $SAVE_ROOT"
