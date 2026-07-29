@echo off
cd /d "%~dp0"
git add incident-report.html
git commit -m "Add/update incident report form"
git push origin main
pause
