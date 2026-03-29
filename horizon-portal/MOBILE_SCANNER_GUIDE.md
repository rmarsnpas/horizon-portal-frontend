# Mobile Receipt Scanner - Quick Start Guide

## 📱 Accessing from iPhone/iPad

### Option 1: Office Wi-Fi (Easiest)

1. **On your work PC**, find the IP address:
   - Open PowerShell
   - Type: `ipconfig`
   - Look for "IPv4 Address" under your Wi-Fi adapter (e.g., `192.168.1.100`)

2. **On your iPhone**:
   - Make sure you're connected to the **same Wi-Fi** as the PC
   - Open Safari browser
   - Go to: `http://192.168.1.100:8080/mobile-receipt-scanner.html`
   - (Replace `192.168.1.100` with your actual PC IP)

3. **Add to Home Screen** (optional):
   - Tap the Share button (square with arrow)
   - Tap "Add to Home Screen"
   - Name it "Receipt Scanner"
   - Now you have a quick-access icon

### Option 2: Remote Access (Anywhere)

Use Tailscale VPN for access from home or while traveling:

1. **Install Tailscale**:
   - PC: Download from https://tailscale.com/download
   - iPhone: Install "Tailscale" app from App Store
   - Sign into same account on both

2. **Find Tailscale IP**:
   - On PC, look for Tailscale IP (starts with 100.x.x.x)
   - Usually shown in Tailscale app

3. **Access from anywhere**:
   - Open Tailscale app on iPhone
   - Connect to VPN
   - Go to: `http://100.x.x.x:8080/mobile-receipt-scanner.html`

---

## 📸 How to Scan Receipts

### Step-by-Step

1. **Open the scanner** (use one of the methods above)

2. **Tap "📸 Capture Receipt"**
   - iPhone will ask for camera permission (tap "Allow")
   - Camera opens automatically

3. **Take the photo**
   - Point at receipt
   - Make sure text is readable
   - Tap the capture button

4. **Fill in details**:
   - **Amount**: Total cost (required)
   - **Category**: Select from dropdown (required)
   - **Date**: Defaults to today (change if needed)
   - **Description**: What was purchased (optional but helpful)
   - **Your Name**: Enter your name (required)
   - **Expense ID**: Leave blank unless linking to existing expense

5. **Tap "💾 Save Receipt"**
   - Receipt uploads automatically
   - Success message appears
   - Data syncs via OneDrive

6. **Done!**
   - Receipt is now in the system
   - Staff can review on accounting dashboard
   - Original photo saved in `uploads/receipts/`

---

## 📋 Categories

Pre-configured expense categories:
- Office Supplies
- Food & Groceries
- Maintenance
- Utilities
- Transportation
- Medical
- Program Materials
- Other

---

## 🔧 Troubleshooting

### "Cannot connect to page"

**Problem**: Can't load the scanner page

**Solutions**:
1. Verify PC is on and portal is running (START-PORTAL.bat)
2. Check you're on same Wi-Fi network as PC
3. Confirm IP address is correct (may change after PC restart)
4. Try `http://127.0.0.1:8080/mobile-receipt-scanner.html` if on the PC itself

### "Camera not working"

**Problem**: Camera doesn't open

**Solutions**:
1. Allow camera permissions when prompted
2. Go to iPhone Settings → Safari → Camera → Allow
3. If using Chrome/Firefox, switch to Safari (better compatibility)
4. Restart Safari and try again

### "Receipt upload failed"

**Problem**: Error message after tapping Save

**Solutions**:
1. Check backend server (Horizon Backend window) is still running
2. Verify firewall allows Node.js (port 3001)
3. Try refreshing the page
4. Check backend console for error messages

### "Receipt saved but don't see it in accounting"

**Problem**: Upload succeeded but not visible in dashboard

**Solutions**:
1. Refresh accounting dashboard page
2. Click "Load Data" button on dashboard
3. Check `accounting.xlsx` in `backend/` folder (should have new row)
4. Verify OneDrive sync is active (system tray icon)

---

## ⚙️ Technical Details

### How It Works

1. **Image Capture**:
   - Uses HTML5 `<input type="file" capture="environment">`
   - Invokes native camera on mobile devices
   - Compresses to JPEG (max 10MB)

2. **Data Submission**:
   - Sends to: `POST /api/accounting/upload-receipt-mobile`
   - Includes both image file and metadata
   - Backend saves to `uploads/receipts/` folder

3. **Data Storage**:
   - Image: Saved as file in `backend/uploads/receipts/`
   - Metadata: Appended to `expenses` sheet in `accounting.xlsx`
   - Status: Set to "Pending Review" automatically

4. **Sync**:
   - OneDrive monitors folder changes
   - Syncs within seconds when online
   - All devices see new receipts automatically

### Security

- Portal runs locally (not on public internet)
- Mobile access requires same network or VPN
- No data sent to external servers
- OneDrive handles encryption and backup

### File Format

Image saved as: `[timestamp]-[random].jpg`
Example: `1738886400123-a3b5c7.jpg`

Metadata stored in Excel:
```
ExpenseID | Date | Category | Amount | Description | StaffName | ReceiptURL | Status
```

---

## 💡 Tips

### Best Practices

1. **Take clear photos**:
   - Good lighting
   - Flat surface
   - All text visible
   - Avoid shadows/glare

2. **Enter receipt date**:
   - Not submission date
   - Helps with accounting reports
   - Default is today (change if old receipt)

3. **Write good descriptions**:
   - "Office Depot - printer paper, staples"
   - "Safeway - house groceries (milk, eggs, bread)"
   - Makes approval faster

4. **Link to expenses**:
   - If you already created expense in accounting dashboard
   - Enter the ExpenseID in "Expense ID" field
   - Attaches receipt to existing entry

### Batch Scanning

For multiple receipts:
1. Scan one, fill details, save
2. Page resets automatically
3. Scan next receipt immediately
4. Much faster than desktop upload

### Offline Mode

Scanner requires live connection to PC. If you lose connection:
1. Take photos with regular iPhone camera app
2. Upload manually later from photo library (coming in future update)
3. Or use Tailscale to maintain connection remotely

---

## 📱 Device Compatibility

**Tested On**:
- iPhone (iOS 13+)
- iPad (iPadOS 13+)
- Safari browser (recommended)

**Also Works On**:
- Android phones (Chrome browser)
- Android tablets
- Any device with camera and browser

---

## 🚀 Future Features (Planned)

- [ ] OCR text extraction from receipts
- [ ] Auto-fill amount from receipt scan
- [ ] Bulk upload from photo library
- [ ] Offline queue (save when no connection)
- [ ] Push notifications on approval/rejection
- [ ] Mileage tracker for transportation expenses

---

## 📞 Support

For issues:
1. Check this troubleshooting guide
2. Verify PC portal is running
3. Test on PC browser first (http://localhost:8080/mobile-receipt-scanner.html)
4. Check backend server console for errors

---

**Document Version**: 1.0
**Last Updated**: February 2026
