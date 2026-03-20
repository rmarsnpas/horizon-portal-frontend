@echo off
REM Stop Horizon House Portal Servers

echo Stopping Horizon House Portal...

REM Kill Node.js backend server
taskkill /FI "WINDOWTITLE eq Horizon Backend*" /F 2>nul

REM Kill Python frontend server
taskkill /FI "WINDOWTITLE eq Horizon Frontend*" /F 2>nul

echo Portal stopped.
timeout /t 2 /nobreak > nul
