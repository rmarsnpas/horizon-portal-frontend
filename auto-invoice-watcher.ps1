# PowerShell script to fully automate invoice PDF deployment
# Watches for changes in invoice folders, regenerates manifest, commits, and pushes automatically

$unpaidPath = "horizon-portal/invoices/unpaid"
$paidPath = "horizon-portal/invoices/paid"
$backendPath = "horizon-portal/backend"
$manifestPath = "horizon-portal/invoices/invoices.json"

# Function to run manifest generator and git push
defaultCommitMsg = "Auto: Update invoices and manifest"
function Run-AutoDeploy {
    Write-Host "[Auto] Running invoice manifest generator..."
    Push-Location $backendPath
    npm run generate:invoices
    Pop-Location

    Write-Host "[Auto] Staging new PDFs and invoices.json..."
    git add $unpaidPath\*.pdf
    git add $paidPath\*.pdf
    git add $manifestPath

    # Only commit if there are staged changes
    $status = git status --porcelain
    if ($status) {
        git commit -m $defaultCommitMsg
        Write-Host "[Auto] Pushing to GitHub..."
        git push
        Write-Host "[Auto] Deploy triggered."
    } else {
        Write-Host "[Auto] No changes to commit."
    }
}

# Set up file system watcher
$watcherUnpaid = New-Object System.IO.FileSystemWatcher $unpaidPath -Property @{ 
    IncludeSubdirectories = $false; 
    NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite' 
}
$watcherPaid = New-Object System.IO.FileSystemWatcher $paidPath -Property @{ 
    IncludeSubdirectories = $false; 
    NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite' 
}

$action = {
    Start-Sleep -Seconds 2  # debounce for rapid changes
    Run-AutoDeploy
}

Register-ObjectEvent $watcherUnpaid Created -Action $action | Out-Null
Register-ObjectEvent $watcherUnpaid Changed -Action $action | Out-Null
Register-ObjectEvent $watcherPaid Created -Action $action | Out-Null
Register-ObjectEvent $watcherPaid Changed -Action $action | Out-Null

Write-Host "[Auto] Watching for invoice changes. Press Ctrl+C to stop."
while ($true) { Start-Sleep -Seconds 60 }
