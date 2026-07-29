# PowerShell script to move all PDFs from your OneDrive invoice folders to your project folders
# Source unpaid and paid folders
$srcUnpaid = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\invoices\unpaid"
$srcPaid = "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\invoices\paid"
# Destination project folders
$dstUnpaid = "C:\Users\rmars\OneDrive\Documents\GitHub\horizon-portal-frontend\horizon-portal\invoices\unpaid"
$dstPaid = "C:\Users\rmars\OneDrive\Documents\GitHub\horizon-portal-frontend\horizon-portal\invoices\paid"

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

Write-Host "All PDFs moved."
