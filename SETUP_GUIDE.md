# Horizon House Portal - Setup Guide
## Complete Deployment Instructions for PC and Mobile Devices

---

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [PC Setup - New Computer](#pc-setup)
4. [Mac Setup - iMac/MacBook](#mac-setup)
5. [Mobile Access - iPhone/iPad](#mobile-access)
6. [OneDrive Sync Configuration](#onedrive-sync)
7. [Starting the Portal](#starting-the-portal)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Options](#advanced-options)

---

## Overview

The Horizon House Portal can run on **unlimited devices** simultaneously:
- **Work PC**: Primary office computer
- **Laptop**: Portable for home or travel
- **Additional PCs**: Staff computers as needed
- **Mobile Devices**: iPhone/iPad for receipt scanning

All devices share the same data via **OneDrive sync**, enabling offline functionality and automatic synchronization.

---

## Prerequisites

### Required Software
- **Node.js** (v14 or higher) - [Download](https://nodejs.org)
- **Python** (v3.7 or higher) - [Download](https://www.python.org/downloads/)
- **Git** (optional for updates) - [Download](https://git-scm.com)
- **OneDrive** (Windows 10/11 built-in)

### Required Access
- OneDrive account with portal files synced
- Wi-Fi network at office (for mobile access)

---

## PC Setup - New Computer

### Step 1: Install Required Software

1. **Install Node.js**
   - Download from https://nodejs.org
   - Run installer, accept defaults
   - Verify installation:
     ```powershell
     node --version
     npm --version
     ```

2. **Install Python**
   - Download from https://www.python.org/downloads/
   - **IMPORTANT**: Check "Add Python to PATH" during installation
   - Verify installation:
     ```powershell
     python --version
     ```

### Step 2: Configure OneDrive Sync

1. Sign into OneDrive on the new PC
2. Wait for sync to complete (check OneDrive system tray icon)
3. Navigate to:
   ```
   C:\Users\[YourName]\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files
   ```
4. Verify these folders exist:
   - `horizon-portal/`
   - `horizon-portal/backend/`
   - `horizon-portal/members/`

### Step 3: Install Backend Dependencies

1. Open **PowerShell** as Administrator
2. Navigate to backend folder:
   ```powershell
   cd "C:\Users\[YourName]\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\backend"
   ```
3. Install dependencies:
   ```powershell
   npm install
   ```
4. Wait for installation to complete (may take 2-3 minutes)

### Step 4: Test the Portal

1. Double-click **START-PORTAL.bat** in:
   ```
   C:\Users\[YourName]\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\
   ```
2. Two command windows will open:
   - **Horizon Backend** (Node.js server on port 3001)
   - **Horizon Frontend** (Python server on port 8080)
3. Browser should automatically open to the Staff Dashboard
4. Test features:
   - Check if members load in accounting dashboard
   - Create a test invoice
   - Verify data saves

### Step 5: Optional - Auto-Start on Login

To make the portal start automatically when you log into Windows:

1. Press `Win + R`, type `shell:startup`, press Enter
2. Right-click in the folder → New → Shortcut
3. Browse to **START-PORTAL.bat**
4. Name it "Horizon Portal"
5. Portal will now start automatically on login

---

## Mac Setup - iMac/MacBook

### Step 1: Install Required Software

1. **Install Homebrew** (package manager for Mac)
   - Open **Terminal** (Applications → Utilities → Terminal)
   - Paste this command:
     ```bash
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     ```
   - Follow the prompts, enter your password when asked
   - Wait for installation (2-5 minutes)

2. **Install Node.js**
   - In Terminal, run:
     ```bash
     brew install node
     ```
   - Verify installation:
     ```bash
     node --version
     npm --version
     ```

3. **Check Python** (usually pre-installed on macOS)
   - Verify version:
     ```bash
     python3 --version
     ```
   - If not installed or version < 3.7, install:
     ```bash
     brew install python3
     ```

4. **Install Git** (if not already installed)
   ```bash
   brew install git
   ```

### Step 2: Install OneDrive

1. Download **OneDrive for Mac** from Mac App Store or:
   - Visit: https://www.microsoft.com/en-us/microsoft-365/onedrive/download
   - Download and install OneDrive
   - Sign in with your Microsoft account

2. Configure OneDrive sync:
   - OneDrive icon appears in menu bar
   - Click icon → Preferences → Account → Choose folders
   - Ensure portal folder is selected for sync
   - Default location: `/Users/[YourName]/OneDrive/`

3. Wait for initial sync to complete

### Step 3: Navigate to Portal Folder

1. Open **Finder**
2. Go to: `OneDrive → Documents → marsliz → Horizon-House → website → index_files`
3. Or use Terminal:
   ```bash
   cd ~/OneDrive/Documents/marsliz/Horizon-House/website/index_files
   ```

### Step 4: Install Backend Dependencies

1. In Terminal, navigate to backend:
   ```bash
   cd ~/OneDrive/Documents/marsliz/Horizon-House/website/index_files/horizon-portal/backend
   ```

2. Install npm packages:
   ```bash
   npm install
   ```

3. Wait for installation (2-3 minutes)

### Step 5: Create Mac Startup Script

1. Create startup script:
   ```bash
   cd ~/OneDrive/Documents/marsliz/Horizon-House/website/index_files
   nano start-portal-mac.sh
   ```

2. Paste this content:
   ```bash
   #!/bin/bash
   # Horizon House Portal Startup Script for Mac
   
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
   echo "Staff Dashboard: http://localhost:8080/staff-intake-portal.html"
   echo "Accounting:      http://localhost:8080/staff-accounting-dashboard.html"
   echo ""
   echo "Opening staff dashboard in browser..."
   echo ""
   
   # Open browser (Windows)

**Solution**: Node.js not installed or not in PATH
1. Reinstall Node.js from https://nodejs.org
2. Make sure to use default installation settings
3. Restart PowerShell after installation

### Problem: "python is not recognized" (Windows)

**Solution**: Python not installed or not in PATH
1. Reinstall Python from https://www.python.org
2. **Check "Add Python to PATH"** during installation
3. Restart PowerShell

### Problem: "command not found: node" (Mac)

**Solution**: Node.js not installed via Homebrew
1. Install Homebrew if needed
2. Run `brew install node`
3. Restart Terminal

### Problem: "command not found: python3" (Mac)

**Solution**: Python3 not installed
1. Run `brew install python3`
2. Use `python3` command (not `python`)
3. Update startup script to use `python3`able:
   ```bash
   chmod +x start-portal-mac.sh
   ```

### Step 6: Test the Portal

1. **Run startup script**:
   ```bash
   ./start-portal-mac.sh
   ```
   
   Or double-click `start-portal-mac.sh` in Finder (may need to:
   - Right-click → Open With → Terminal
   - Allow in System Preferences → Security if prompted)

2. **Two Terminal windows will open**:
   - Backend server (Node.js on port 3001)
   - Frontend server (Python on port 8080)

3. **Browser opens** automatically to staff dashboard

4. **Test features**:
   - Check if members load in accounting dashboard
   - Create a test invoice
   - Verify data saves to Excel

### Step 7: Create Desktop Shortcut (Optional)

**Option A: Alias**
1. Open Finder → Go to portal folder
2. Right-click `start-portal-mac.sh`
3. Make Alias
4. Drag alias to Desktop
5. Rename to "Start Horizon Portal"

**Option B: Application Bundle**
1. Open **Automator** (Applications → Automator)
2. Choose "Application"
3. Search for "Run Shell Script"
4. Paste:
   ```bash
   ~/OneDrive/Documents/marsliz/Horizon-House/website/index_files/start-portal-mac.sh
   ```
5. File → Save → Save to Desktop as "Horizon Portal"
6. Now you can double-click to start portal

### Step 8: Optional - Auto-Start on Login

1. Open **System Preferences** → Users & Groups
2. Click your username
3. Click "Login Items" tab
4. Click "+" button
5. Navigate to your startup application (from Step 7, Option B)
6. Select it and click "Add"
7. Portal will start automatically when you log in

### Mac-Specific Notes

**Python Command**: Use `python3` instead of `python`:
```bash
python3 -m http.server 8080
```

**Terminal vs PowerShell**: 
- Mac uses bash/zsh instead of PowerShell
- Commands are mostly the same for Node.js
- Use `ls` instead of `dir`, `rm` instead of `del`

**Stopping the Portal**:
- Close both Terminal windows, or
- Press `Control + C` in each Terminal window

**Finding Your IP Address** (for mobile):
```bash
ipconfig getifaddr en0
```
Or: System Preferences → Network → Wi-Fi → Advanced → TCP/IP

**Firewall Configuration**:
- System Preferences → Security & Privacy → Firewall
- If enabled, click "Firewall Options"
- Add Node and Python if prompted

---

## Mobile Access - iPhone/iPad

### Option 1: Local Network (Office Wi-Fi Only)

1. **Find Your PC's IP Address** (on the work PC):
   ```powershell
   ipconfig
   ```
   Look for "IPv4 Address" (e.g., 192.168.1.100)

2. **Access from iPhone** (on same Wi-Fi):
   - Open Safari
   - Go to: `http://192.168.1.100:8080/mobile-receipt-scanner.html`
   - Bookmark this page for easy access

3. **Scan Receipts**:
   - Tap "📸 Capture Receipt"
   - Allow camera access when prompted
   - Take photo of receipt
   - Fill in amount, category, date, description
   - Tap "💾 Save Receipt"
   - Receipt syncs via OneDrive automatically

### Option 2: Remote Access (Home or Travel) - Tailscale VPN

For access when **not on office Wi-Fi**, set up Tailscale mesh network:

1. **Install Tailscale on PC**:
   - Download from https://tailscale.com/download
   - Install and sign up (free account)
   - Note your PC's Tailscale IP (e.g., 100.64.0.1)

2. **Install Tailscale on iPhone**:
   - Download "Tailscale" app from App Store
   - Sign in with same account
   - Enable VPN

3. **Access Portal**:
   - Open Safari while connected to Tailscale
   - Go to: `http://100.64.0.1:8080/mobile-receipt-scanner.html`
   - Works from anywhere with internet

### Mobile Bookmarks

Add these to your iPhone home screen for quick access:

**Receipt Scanner**:
```
http://[PC-IP]:8080/mobile-receipt-scanner.html
```

**Staff Dashboard** (view only on mobile):
```
http://[PC-IP]:8080/staff-dashboard.html
```

---

## OneDrive Sync Configuration

### Verify Sync Status

1. Right-click OneDrive icon in system tray
2. Click "Settings" → "Account" → "Choose folders"
3. Ensure this path is checked:
   ```
   Documents\marsliz\Horizon-House\website\index_files
   ```

### Important Sync Notes

- **members.xlsx**: Already synced via OneDrive link in backend
- **accounting.xlsx**: Located in `horizon-portal/backend/`, syncs automatically
- **Receipts**: Photos in `uploads/receipts/` sync across all devices
- **Changes sync within seconds** when online
- **Offline changes** sync when connection restored

### Recommended: Move accounting.xlsx to OneDrive

For better multi-device sync:

1. Move `accounting.xlsx` to same OneDrive folder as `members.xlsx`
2. Update `server.js` to use OneDrive link (optional)
3. All devices will share live data instantly

---

## Starting the Portal

### Quick Start (Recommended)

Double-click **START-PORTAL.bat**

### Manual Start (Troubleshooting)

1. **Start Backend**:
   ```powershell
   cd horizon-portal\backend
   node server.js
   ```
   Wait for: "Server running on port 3001"

2. **Start Frontend** (new PowerShell window):
   ```powershell
   cd horizon-portal
   python -m http.server 8080
   ```
   Wait for: "Serving HTTP on :: port 8080"

3. **Open Browser**:
   - Staff Dashboard: http://localhost:8080/staff-dashboard.html
   - Accounting: http://localhost:8080/staff-accounting-dashboard.html
   - Men's Kiosk: http://localhost:8080/kiosk-men.html
   - Women's Kiosk: http://localhost:8080/kiosk-women.html

### Stopping the Portal

Double-click **STOP-PORTAL.bat** or close both command windows.

---

## Troubleshooting

### Problem: "node is not recognized"

**Solution**: Node.js not installed or not in PATH
1. Reinstall Node.js from https://nodejs.org
2. Make sure to use default installation settings
3. Restart PowerShell after installation

### Problem: "python is not recognized"

**Solution**: Python not installed or not in PATH
1. Reinstall Python from https://www.python.org
2. **Check "Add Python to PATH"** during installation
3. Restart PowerShell

### Problem: "Port 3001 already in use"

**Solution**: Another instance is running
1. Run **STOP-PORTAL.bat**
2. Open Task Manager (Ctrl+Shift+Esc)
3. End any "node.exe" processes
4. Try **START-PORTAL.bat** again

### Problem: "Port 8080 already in use"

**Solution**: Another program using port 8080
1. Run **STOP-PORTAL.bat**
2. End any "python.exe" processes in Task Manager
3. Or edit START-PORTAL.bat to use port 8081:
   ```batch
   python -m http.server 8081
   ```

### Problem: Mobile devices can't connect

**Solution**: Firewall blocking connection
1. Press `Win + R`, type `firewall.cpl`
2. Click "Allow an app through firewall"
3. Add both `node.exe` and `python.exe`
4. Check "Private" and "Public" boxes
5. Restart START-PORTAL.bat

### Problem: Member data not loading

**Solution**: OneDrive sync issue
1. Check OneDrive sync status (system tray icon)
2. Verify `members.xlsx` exists in backend folder
3. Open `members.xlsx` to confirm data present
4. Check backend console for error messages

### Problem: Receipt upload fails on mobile

**Solution**: CORS or network issue
1. Verify PC IP address hasn't changed
2. Update mobile bookmark with new IP
3. Check PC firewall allows port 3001
4. Ensure both devices on same Wi-Fi network

---

## Advanced Options

### Option A: Cloud Hosting (Always Online)

For 24/7 access without running PC:

**Platforms**:
- Render.com (free tier available)
- Heroku (free tier available)
- Azure App Service
- AWS Elastic Beanstalk

**Setup**:
1. Push code to GitHub
2. Connect platform to repository
3. Configure environment variables
4. Deploy frontend and backend separately

### Option B: Dedicated Server PC

Convert old PC into always-on portal server:

1. Install Windows 10/11 on spare computer
2. Follow PC Setup steps above
3. Configure START-PORTAL.bat to run on login
4. Set PC to never sleep:
   - Settings → System → Power & Sleep → Never
5. Place on office network with static IP
6. Access from all devices via local IP

### Option C: Network Attached Storage (NAS)

If you have a Synology, QNAP, or similar NAS:

1. Install Docker on NAS
2. Create Docker container with Node.js
3. Mount OneDrive folder to container
4. Run portal from NAS (always on)

---

## Portal URLs Reference

### Staff Pages
- Dashboard: http://localhost:8080/staff-dashboard.html
- Accounting: http://localhost:8080/staff-accounting-dashboard.html
- Intake Portal: http://localhost:8080/staff-intake-portal.html
- Emergency Contacts: http://localhost:8080/staff-emergency-contacts.html
- Reviews: http://localhost:8080/staff-reviews.html

### Kiosk Pages
- Men's Sign-In: http://localhost:8080/kiosk-men.html
- Women's Sign-In: http://localhost:8080/kiosk-women.html

### Mobile Pages
- Receipt Scanner: http://localhost:8080/mobile-receipt-scanner.html

### Backend API
- Health Check: http://localhost:3001/api/health
- Members: http://localhost:3001/api/getMember?id=101

---

## Security Notes

- Portal runs on **localhost** (secure by default)
- OneDrive provides automatic **backup** and **versioning**
- No internet exposure unless you configure cloud hosting
- Mobile access only works on **trusted Wi-Fi** or via VPN
- Receipts stored locally, synced via OneDrive encryption

---

## Support

For issues or questions:
1. Check this guide's Troubleshooting section
2. Review backend console logs (command window)
3. Check browser DevTools console (F12)
4. Verify OneDrive sync status

---

## Updates and Maintenance

### Updating the Portal

1. OneDrive automatically syncs code changes
2. After sync completes, restart portal:
   - Run **STOP-PORTAL.bat**
   - Run **START-PORTAL.bat**

### Backing Up Data
### Windows PC
**Start Portal**: Double-click START-PORTAL.bat
**Stop Portal**: Double-click STOP-PORTAL.bat or close windows
**File Location**: `C:\Users\[Name]\OneDrive\...\horizon-portal\`

### Mac
**Start Portal**: Double-click start-portal-mac.sh or run `./start-portal-mac.sh`
**Stop Portal**: Close Terminal windows or press Control+C
**File Location**: `/Users/[Name]/OneDrive/.../horizon-portal/`
**Get IP**: `ipconfig getifaddr en0`

### Universal
**Mobile Scanner**: http://[PC-IP]:8080/mobile-receipt-scanner.html
**Staff Dashboard**: http://localhost:8080/staff-dashboard.html
**Accounting**: http://localhost:8080/staff-accounting-dashboard.html

**Ports**:
- Backend: 3001
- Frontend: 8080

**Data Files**:
- Members: `backend/members.xlsx`
- Accounting: `backend/accounting.xlsx`
- Receipts: `backend/uploads/receipts/
**Start Portal**: Double-click START-PORTAL.bat
**Stop Portal**: Double-click STOP-PORTAL.bat or close windows
**Mobile Scanner**: http://[PC-IP]:8080/mobile-receipt-scanner.html
**Staff Dashboard**: http://localhost:8080/staff-dashboard.html
**Accounting**: http://localhost:8080/staff-accounting-dashboard.html

**Ports**:
- Backend: 3001
- Frontend: 8080

**File Locations**:
- Portal: `C:\Users\[Name]\OneDrive\...\horizon-portal\`
- Data: `backend\members.xlsx` and `backend\accounting.xlsx`
- Receipts: `backend\uploads\receipts\`

---

**Document Version**: 1.0
**Last Updated**: February 2026
