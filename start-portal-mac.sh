#!/bin/bash
# Horizon House Portal Startup Script for Mac
# Double-click to start both servers

echo "========================================"
echo " Horizon House Portal Starting..."
echo "========================================"
echo ""

# Get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Start Backend Server
echo "Starting Backend Server (Port 3001)..."
osascript -e 'tell app "Terminal" to do script "cd ~/OneDrive/Documents/marsliz/Horizon-House/website/index_files/horizon-portal/backend && node server.js"'
sleep 3

# Start Frontend Server
echo "Starting Frontend Server (Port 8080)..."
osascript -e 'tell app "Terminal" to do script "cd ~/OneDrive/Documents/marsliz/Horizon-House/website/index_files/horizon-portal && python3 -m http.server 8080"'
sleep 2

echo ""
echo "========================================"
echo " Portal Started Successfully!"
echo "========================================"
echo ""
echo "Backend API: http://localhost:3001"
echo "Frontend:    http://localhost:8080"
echo ""
echo "Kiosks:"
echo " - Men:   http://localhost:8080/kiosk-men.html"
echo " - Women: http://localhost:8080/kiosk-women.html"
echo ""
echo "Staff:"
echo " - Intake:     http://localhost:8080/staff-intake-portal.html"
echo " - Accounting: http://localhost:8080/staff-accounting-dashboard.html"
echo " - PBX System: http://localhost:8080/pbx-dashboard.html"
echo ""
echo "Mobile Receipt Scanner:"
echo " - http://localhost:8080/mobile-receipt-scanner.html"
echo ""
echo "Opening staff dashboard in browser..."
echo ""

# Open browser
sleep 2
open http://localhost:8080/staff-intake-portal.html

echo "Portal is running in separate Terminal windows."
echo "Close those Terminal windows to stop the servers."
echo ""
echo "You can close this window now."
