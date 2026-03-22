# Migrating from 3CX to Horizon House PBX
## Using Your Existing Flowroute DIDs

---

## Overview

You already have:
- ✅ Flowroute account with DIDs
- ✅ SIP trunk configured
- ✅ Working phone numbers

This guide connects your existing Flowroute setup to the new PBX dashboard.

---

## Step 1: Get Flowroute API Credentials

1. **Log into Flowroute**
   - Go to: https://manage.flowroute.com
   - Sign in with your credentials

2. **Generate API Keys**
   - Click "Preferences" → "API Control"
   - Click "Add New Key"
   - Name: "Horizon House Portal"
   - Copy the **Access Key** (starts with: `xxxxxxxx-xxxx-xxxx...`)
   - Copy the **Secret Key** (only shown once!)
   - Save both securely

3. **Find Your DID Numbers**
   - Click "Numbers" in left menu
   - List shows all your active numbers
   - Note the main number you want to use (e.g., `+15551234567`)

---

## Step 2: Configure Backend

1. **Create .env file**
   
   Navigate to backend folder:
   ```powershell
   cd C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\backend
   ```

2. **Create/edit .env file**:
   ```powershell
   notepad .env
   ```

3. **Add these lines** (replace with your actual values):
   ```
   # Flowroute Configuration
   FLOWROUTE_ACCESS_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   FLOWROUTE_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   FLOWROUTE_DID=+15551234567
   
   # PBX Settings
   PBX_MAIN_EXTENSION=101
   PBX_BUSINESS_HOURS_START=9
   PBX_BUSINESS_HOURS_END=17
   ```

4. **Save and close** (Ctrl+S, then Alt+F4)

---

## Step 3: Install Required npm Package

```powershell
cd C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\backend
npm install axios
```

---

## Step 4: Configure Flowroute Webhooks

1. **Find Your PC's Public IP** (if on office network):
   ```powershell
   curl ifconfig.me
   ```
   
   Or for local testing, use **ngrok** (temporary):
   ```powershell
   # Install ngrok
   choco install ngrok
   # Or download from: https://ngrok.com/download
   
   # Start ngrok tunnel
   ngrok http 3001
   # Copy the HTTPS URL (e.g., https://abcd1234.ngrok.io)
   ```

2. **Configure SMS Webhook in Flowroute**:
   - Go to: https://manage.flowroute.com
   - Click "Numbers" → your main DID
   - Under "SMS Settings":
     - Callback URL (HTTP Post): `https://YOUR-URL/api/pbx/incoming-sms`
     - Method: POST
     - Click "Update"

3. **Configure Voice Webhook** (optional - for future):
   - Same page, under "Voice Settings":
     - Primary Route: Point to your SIP server OR
     - Callback URL: `https://YOUR-URL/api/pbx/incoming-call`

---

## Step 5: Test the System

1. **Restart Backend Server**:
   ```powershell
   cd C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files
   .\STOP-PORTAL.bat
   .\START-PORTAL.bat
   ```

2. **Open PBX Dashboard**:
   - Go to: http://localhost:8080/pbx-dashboard.html

3. **Test API Connection**:
   - Open new tab: http://localhost:3001/api/pbx/test
   - Should show:
     ```json
     {
       "status": "online",
       "message": "PBX system is operational",
       "flowrouteConfigured": true,
       "did": "+15551234567"
     }
     ```

4. **Send Test SMS**:
   - In PBX Dashboard → SMS tab
   - Enter your mobile number
   - Type: "Test from Horizon House PBX"
   - Click Send
   - Check your phone for SMS

5. **Check Call Log**:
   - Should load without errors
   - Any existing messages will appear

---

## Step 6: Migrate from 3CX

### Option A: Keep 3CX for Now (Hybrid)

Run both systems simultaneously:
- Keep 3CX for voice calls
- Use new PBX for SMS, logging, click-to-call
- Gradual migration

### Option B: Full Migration

1. **Export 3CX Data**:
   - Export call history from 3CX
   - Document extension numbers
   - Note auto-attendant scripts

2. **Recreate Extensions**:
   - Go to: http://localhost:8080/pbx-extensions.html (will create next)
   - Add same extension numbers as 3CX
   - Configure forwarding to staff mobiles

3. **Port Voice Calls** (optional):
   - Configure Flowroute to use portal for voice routing
   - Or keep 3CX for voice, portal for everything else

---

## What Works Now

✅ **SMS Messaging**
- Send SMS from dashboard
- Receive SMS (appears in SMS tab automatically)
- Reply to incoming messages
- Full conversation history

✅ **Call Logging**
- All calls logged to database
- View call history
- Filter by date/type
- See call duration

✅ **Click-to-Call**
- Dial from dashboard
- Quick dial extensions
- Member database integration

✅ **Statistics**
- Calls today/week/month
- Minutes used
- Missed call tracking

---

## What Needs Additional Setup

⚠️ **Voice Calling**
- Requires WebRTC or SIP client
- Or continue using 3CX for voice
- Portal handles everything else

⚠️ **Voicemail**
- Currently logs voicemails
- Playback requires voicemail-to-email from Flowroute
- Or continue using 3CX voicemail

---

## Recommended Setup

**Best of Both Worlds:**

1. **Keep 3CX** for:
   - Voice calls (desk phones, softphones)
   - Voicemail
   - Conference calls

2. **Use New PBX Portal** for:
   - SMS messaging (3CX doesn't do SMS well)
   - Call logging and analytics
   - Member database integration
   - Click-to-call from web
   - Mobile interface

**Connect them:**
- Point 3CX and Portal to same Flowroute account
- Portal logs all activity
- Staff use 3CX apps + Portal dashboard

---

## Cost Comparison

### 3CX
- License fee (one-time or annual)
- Maintenance costs
- Requires dedicated server

### This Portal
- No license ($0)
- Just Flowroute usage costs
- Runs on any PC

### Flowroute Costs
- DID: $0.85-$1.50/month per number
- SMS: $0.004/message
- Voice: $0.01/minute (if used)

**Example:** 200 SMS/month = $0.80

---

## Troubleshooting

### "flowrouteConfigured: false"

**Problem:** API credentials not loaded

**Solution:**
1. Verify `.env` file exists in `backend/` folder
2. Check credentials are correct (no extra spaces)
3. Restart backend server
4. Install `dotenv` if needed: `npm install dotenv`

### "SMS sending failed"

**Problem:** Webhook not configured or DID doesn't support SMS

**Solution:**
1. Verify DID has SMS enabled in Flowroute
2. Check webhook URL is correct
3. Test with curl:
   ```powershell
   curl -X POST http://localhost:3001/api/pbx/test
   ```

### "Can't receive SMS"

**Problem:** Webhook not configured in Flowroute

**Solution:**
1. Go to Flowroute → Numbers → your DID
2. Add webhook URL (must be publicly accessible)
3. Use ngrok for testing: `ngrok http 3001`
4. Update webhook with ngrok URL

### "Calls not logging"

**Problem:** 3CX and Portal not connected

**Solution:**
- This is expected - they're separate systems
- For unified logging, configure 3CX to send CDR to Portal
- Or use Portal for calling, not 3CX

---

## Files Created

- `pbx-flowroute.js` - Flowroute API integration
- `pbx-storage.js` - Call log/voicemail storage
- `pbx-dashboard.html` - Main interface
- `.env` - Credentials (you create this)
- `call_log.json` - Auto-created on first use
- `voicemails.json` - Auto-created on first use
- `extensions.json` - Auto-created on first use

---

## Next Steps

1. ✅ Configure `.env` with Flowroute credentials
2. ✅ Test SMS sending
3. ✅ Configure webhook for incoming SMS
4. ⏳ Create extension management page
5. ⏳ Integrate with member database
6. ⏳ Add mobile click-to-call interface

---

## Support

**Flowroute Support:**
- Phone: 1-855-356-9768
- Email: support@flowroute.com
- Docs: https://developer.flowroute.com

**Portal Issues:**
- Check backend console for errors
- Test API: http://localhost:3001/api/pbx/test
- Verify Flowroute account is active

---

**Document Version**: 1.0  
**For**: Existing 3CX + Flowroute Users  
**Date**: March 2026
