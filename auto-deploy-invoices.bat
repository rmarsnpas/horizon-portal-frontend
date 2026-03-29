@echo off
REM Auto-commit and push invoices and PDFs to GitHub for deployment

REM Change to your project directory if needed
REM cd path\to\your\project

echo Adding updated invoices and PDFs...
git add horizon-portal/invoices/invoices.json horizon-portal/invoices/unpaid/* horizon-portal/invoices/paid/*

echo Committing changes...
git commit -m "Auto-update invoices and PDFs"

echo Pushing to GitHub...
git push

echo Done! Your deployment will update automatically if connected to Vercel/Netlify.
pause
