@echo off
echo Attempting to push changes...
git config core.compression 0
git config core.fscache false
set GIT_OPTIONAL_LOCKS=0
git add drug-screen.html
git commit -m "Update drug screen: checkboxes, conditional sections, optional member sig"
git push origin main
pause
