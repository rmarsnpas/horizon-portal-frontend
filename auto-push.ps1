# Auto-push script for frontend repository
# Run this after uploading files to automatically commit and push changes

$ErrorActionPreference = "Stop"

Write-Host "Checking for changes in frontend repository..." -ForegroundColor Cyan

# Check if there are any changes
$status = git status --porcelain
if ($status) {
    Write-Host "Found changes:" -ForegroundColor Yellow
    git status --short
    
    # Add all changes
    git add .
    
    # Create commit with timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commitMessage = "Auto-push: Files updated on $timestamp"
    git commit -m $commitMessage
    
    # Push to main branch
    Write-Host "Pushing to origin/main..." -ForegroundColor Green
    git push origin main
    
    Write-Host "✓ Changes pushed successfully!" -ForegroundColor Green
} else {
    Write-Host "No changes to push." -ForegroundColor Gray
}
