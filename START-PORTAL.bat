@echo off
REM Horizon House Portal Auto-Starter
REM Double-click this file to start both servers

echo ========================================
echo  Horizon House Portal Starting...
echo ========================================
echo.

REM Change to the portal directory
cd /d "%~dp0"

REM Start Backend Server (Node.js)
echo Starting Backend Server (Port 3001)...
start "Horizon Backend" cmd /k "cd horizon-portal\backend && node server.js"
timeout /t 3 /nobreak > nul

REM Start Frontend Server (Python)
echo Starting Frontend Server (Port 8080)...
start "Horizon Frontend" cmd /k "cd horizon-portal && python -m http.server 8080"
timeout /t 2 /nobreak > nul

echo.
echo ========================================
echo  Portal Started Successfully!
echo ========================================
echo.
echo Backend API: http://localhost:3001
echo Frontend:    http://localhost:8080
echo.
echo Kiosks:
echo  - Men:   http://localhost:8080/kiosk-men.html
echo  - Women: http://localhost:8080/kiosk-women.html
echo.
echo Staff:
echo  - Intake:     http://localhost:8080/staff-intake-portal.html
echo  - Accounting: http://localhost:8080/staff-accounting-dashboard.html
echo  - PBX System: http://localhost:8080/pbx-dashboard.html
echo.
echo Mobile Receipt Scanner:
echo  - http://localhost:8080/mobile-receipt-scanner.html
echo.
echo Press any key to open staff dashboard in browser...
pause > nul

REM Open staff dashboard in default browser
start http://localhost:8080/staff-intake-portal.html

echo.
echo Portal is running. Do NOT close the server windows.
echo Close this window to continue working.
timeout /t 3 /nobreak > nul
exit
