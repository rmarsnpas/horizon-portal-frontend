# Sync local Excel file to Azure Blob Storage
# Usage: .\sync-to-azure.ps1

$localFilePath = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\backend\members.xlsx"
$azureBlobUrl = "https://hhcloudfiles.blob.core.windows.net/horizon-portal/HHcensus%20(version%201).xlsx?sp=rw&st=2026-01-21T16:06:05Z&se=2026-03-21T23:21:05Z&spr=https&sv=2024-11-04&sr=c&sig=ezwDqZmACNoaQ%2FLkCmWAc2xoYRToA%2BROWoSnrZwOGNQ%3D"

Write-Host "Syncing Excel file to Azure Blob Storage..." -ForegroundColor Cyan

if (-not (Test-Path $localFilePath)) {
    Write-Host "ERROR: Local file not found at: $localFilePath" -ForegroundColor Red
    Write-Host "Please update the `$localFilePath variable with your actual file location." -ForegroundColor Yellow
    exit 1
}

try {
    # Upload file using Invoke-RestMethod
    $fileBytes = [System.IO.File]::ReadAllBytes($localFilePath)
    $headers = @{
        "x-ms-blob-type" = "BlockBlob"
        "Content-Type" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    }
    
    Invoke-RestMethod -Uri $azureBlobUrl -Method Put -Headers $headers -Body $fileBytes -ContentType "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    
    Write-Host "SUCCESS: File uploaded to Azure Blob Storage!" -ForegroundColor Green
    Write-Host "Portal will use the updated data immediately." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to upload file" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
