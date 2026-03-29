# PowerShell script to automate invoice manifest generation and GitHub push
# Place this script in the root of your project (where the .git folder is)

# Step 1: Run the manifest generation script
Write-Host "Running invoice manifest generator..."
cd "horizon-portal/backend"
npm run generate:invoices
cd ../..

# Step 2: Stage all new/changed invoice PDFs and manifest
Write-Host "Staging new PDFs and invoices.json..."
git add horizon-portal/invoices/unpaid/*.pdf
git add horizon-portal/invoices/paid/*.pdf
git add horizon-portal/invoices/invoices.json

# Step 3: Commit changes
$commitMsg = Read-Host "Enter a commit message for the new invoices"
git commit -m $commitMsg

# Step 4: Push to GitHub
Write-Host "Pushing to GitHub..."
git push

Write-Host "Done! Vercel will deploy your changes automatically."
