# PowerShell script to fully automate invoice PDF transfer, manifest generation, commit, and push
# Watches your OneDrive invoice folders, moves new PDFs to the project, regenerates manifest, commits, and pushes

$srcUnpaid = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\invoices\unpaid"
$srcPaid = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\invoices\paid"
$dstUnpaid = "C:\Users\rmars\OneDrive\Documents\GitHub\horizon-portal-frontend\horizon-portal\invoices\unpaid"
$dstPaid = "C:\Users\rmars\OneDrive\Documents\GitHub\horizon-portal-frontend\horizon-portal\invoices\paid"
$backendPath = "C:\Users\rmars\OneDrive\Documents\GitHub\horizon-portal-frontend\horizon-portal\backend"
$manifestPath = "C:\Users\rmars\OneDrive\Documents\GitHub\horizon-portal-frontend\horizon-portal\invoices\invoices.json"
$defaultCommitMsg = "Auto: Move invoices, update manifest"

function Move-And-Deploy {
    # Move unpaid PDFs
    Get-ChildItem -Path $srcUnpaid -Filter *.pdf | ForEach-Object {
        Move-Item $_.FullName -Destination $dstUnpaid -Force
        Write-Host "Moved: $($_.Name) to unpaid folder"
    }
    # Move paid PDFs
    Get-ChildItem -Path $srcPaid -Filter *.pdf | ForEach-Object {
        Move-Item $_.FullName -Destination $dstPaid -Force
        Write-Host "Moved: $($_.Name) to paid folder"
    }
    # Run manifest generator
    Write-Host "[Auto] Running invoice manifest generator..."
    Push-Location $backendPath
    npm run generate:invoices
    Pop-Location
    # Stage and commit
    Write-Host "[Auto] Staging and committing..."
    git add $dstUnpaid\*.pdf
    git add $dstPaid\*.pdf
    git add $manifestPath
    $status = git status --porcelain
    if ($status) {
        git commit -m $defaultCommitMsg
        git push
        Write-Host "[Auto] Deploy triggered."
    } else {
        Write-Host "[Auto] No changes to commit."
    }
}

# Watcher for OneDrive unpaid and paid folders
$watcherUnpaid = New-Object System.IO.FileSystemWatcher $srcUnpaid -Property @{ 
    IncludeSubdirectories = $false; 
    NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite' 
}
$watcherPaid = New-Object System.IO.FileSystemWatcher $srcPaid -Property @{ 
    IncludeSubdirectories = $false; 
    NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite' 
}

$action = {
    Start-Sleep -Seconds 2  # debounce
    Move-And-Deploy
}

Register-ObjectEvent $watcherUnpaid Created -Action $action | Out-Null
Register-ObjectEvent $watcherUnpaid Changed -Action $action | Out-Null
Register-ObjectEvent $watcherPaid Created -Action $action | Out-Null
Register-ObjectEvent $watcherPaid Changed -Action $action | Out-Null

Write-Host "[Auto] Watching OneDrive invoice folders. Press Ctrl+C to stop."
while ($true) { Start-Sleep -Seconds 60 }
