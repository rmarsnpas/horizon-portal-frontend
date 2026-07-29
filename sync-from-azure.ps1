# Download Excel file from Azure Blob Storage to local PC
# Usage: .\sync-from-azure.ps1

$localFilePath = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\backend\members.xlsx"
$azureBlobUrl = "https://hhcloudfiles.blob.core.windows.net/horizon-portal/HHcensus%20(version%201).xlsx?sp=rw&st=2026-01-21T16:06:05Z&se=2026-03-21T23:21:05Z&spr=https&sv=2024-11-04&sr=c&sig=ezwDqZmACNoaQ%2FLkCmWAc2xoYRToA%2BROWoSnrZwOGNQ%3D"

Write-Host "Downloading Excel file from Azure Blob Storage..." -ForegroundColor Cyan

try {
    # Create directory if it doesn't exist
    $directory = Split-Path -Parent $localFilePath
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    # Download file
    Invoke-WebRequest -Uri $azureBlobUrl -OutFile $localFilePath
    
    Write-Host "SUCCESS: File downloaded to: $localFilePath" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to download file" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
