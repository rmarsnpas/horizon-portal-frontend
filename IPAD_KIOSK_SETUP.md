# iPad Kiosk Mode Setup - Men's Kiosk Only

## Overview
Lock the iPad to display only the men's kiosk webpage with password-protected exit.

## Men's Kiosk URL
```
https://indexfiles.vercel.app/horizon-portal/kiosk-men.html
```

## Setup Instructions

### Step 1: Enable Guided Access
1. Open **Settings** → **Accessibility**
2. Scroll down and tap **Guided Access** (under "General" section)
3. Toggle **Guided Access** to **ON**
4. Tap **Passcode Settings**
5. Tap **Set Guided Access Passcode**
6. Enter a 6-digit passcode (recommend: something easy for staff but not residents)
7. Re-enter the passcode to confirm
8. (Optional) Toggle **Face ID** or **Touch ID** for faster staff access

### Step 2: Configure Safari for Kiosk Mode
1. Open **Safari** on the iPad
2. Navigate to: `https://indexfiles.vercel.app/horizon-portal/kiosk-men.html`
3. Tap the **Share** button (square with arrow)
4. Tap **Add to Home Screen**
5. Name it: "Men's Kiosk"
6. Tap **Add**

### Step 3: Lock iPad to Men's Kiosk
1. Open the **Men's Kiosk** icon from the home screen
2. Wait for the page to fully load
3. **Triple-click** the **Home button** (or Side button on newer iPads)
4. Guided Access screen appears
5. (Optional) Circle any areas you want to disable (like the address bar)
6. Tap **Options** in bottom left:
   - Turn OFF **Touch** (prevents tapping away from kiosk)
   - Turn OFF **Motion** (prevents device rotation affecting display)
   - Turn OFF **Keyboards** (if you don't want residents typing)
   - Turn OFF **Volume Buttons**
   - Set **Time Limit** if desired (e.g., auto-exit after 12 hours)
7. Tap **Done**
8. Tap **Start** in top right corner
9. iPad is now locked to the men's kiosk!

### Step 4: Exiting Kiosk Mode (Staff Only)
1. **Triple-click** the **Home button** (or Side button)
2. Enter the **6-digit passcode** you set in Step 1
3. Tap **End** in top left
4. iPad is unlocked

## Additional Security Options

### Option A: Restrict Home Screen Access
1. Go to **Settings** → **Screen Time**
2. Tap **Content & Privacy Restrictions**
3. Turn on **Content & Privacy Restrictions**
4. Set a different passcode (not the same as Guided Access)
5. Under **Allowed Apps**, turn OFF:
   - Safari (forces use of home screen icon only)
   - App Store
   - Camera
   - FaceTime
   - Any other apps residents shouldn't access

### Option B: Single App Mode (Advanced - requires MDM)
If you have Mobile Device Management (MDM) software:
1. Configure **Single App Mode** through your MDM
2. Lock to Safari with only the kiosk URL allowed
3. This is more secure but requires MDM setup (e.g., Apple Business Manager)

## Recommended Settings for Kiosk iPad
- **Settings** → **Display & Brightness**:
  - Set **Auto-Lock** to **Never**
  - Enable **Raise to Wake** OFF
  
- **Settings** → **Notifications**:
  - Turn OFF all notification previews
  
- **Settings** → **Do Not Disturb**:
  - Enable **Scheduled** for 24/7 quiet mode

## Troubleshooting

**iPad keeps timing out:**
- Check Settings → Display & Brightness → Auto-Lock is set to "Never"
- Keep iPad plugged into power

**Guided Access won't start:**
- Make sure you triple-clicked fast enough
- Try Settings → Accessibility → Guided Access → toggle OFF then ON again

**Forgot the passcode:**
- You'll need to reset the iPad (Settings → General → Transfer or Reset iPad)
- Or use iTunes/Finder to restore the device

**Page doesn't load:**
- Check WiFi connection
- Verify URL is correct: https://indexfiles.vercel.app/horizon-portal/kiosk-men.html

## Quick Reference Card (Print & Post)

```
╔════════════════════════════════════════╗
║     MEN'S KIOSK IPAD - STAFF ONLY      ║
╠════════════════════════════════════════╣
║                                        ║
║  TO EXIT KIOSK MODE:                   ║
║  1. Triple-click Home button           ║
║  2. Enter passcode: [WRITE HERE]       ║
║  3. Tap "End"                          ║
║                                        ║
║  TO RE-LOCK:                           ║
║  1. Open "Men's Kiosk" app             ║
║  2. Triple-click Home button           ║
║  3. Tap "Start"                        ║
║                                        ║
╚════════════════════════════════════════╝
```

## Security Best Practices
- Change the Guided Access passcode monthly
- Don't share the passcode with residents
- Keep a backup passcode written down in a secure location (office safe)
- Test the setup weekly to ensure it's still locked properly
- Consider using different passcodes for men's vs women's kiosks

## Notes
- The kiosk page auto-refreshes status every 30 seconds
- Internet connection required for real-time updates
- Backend API: https://horizon-portal-backend-production-3532.up.railway.app
- If internet fails, status board will show last cached data
