# Horizon House PBX System
## Complete Phone System Setup Guide

---

## Overview

Your new PBX (Private Branch Exchange) system provides:
- ✅ Full phone system with extensions
- ✅ Incoming/outgoing call management
- ✅ SMS/text messaging
- ✅ Voicemail with transcription
- ✅ Call recording & logging
- ✅ Click-to-call from member database
- ✅ Professional call routing

---

## Setup Options

### Option 1: Twilio (Recommended - Cloud-Based)

**Pros:**
- No hardware needed
- Pay-as-you-go ($1/month per number + usage)
- Works from anywhere
- Professional features included
- Easy setup

**Costs:**
- Phone number: $1/month
- Incoming calls: $0.0085/minute
- Outgoing calls: $0.013/minute
- SMS: $0.0075 per message
- **Example:** 500 minutes/month = ~$8-10/month

**Setup Steps:**

1. **Create Twilio Account**
   - Visit: https://www.twilio.com/try-twilio
   - Sign up (free trial includes $15 credit)
   - Verify your email and phone

2. **Get Your Credentials**
   - Go to Twilio Console
   - Copy your **Account SID** (starts with AC...)
   - Copy your **Auth Token** (click to reveal)
   - Save these securely

3. **Buy a Phone Number**
   - In Twilio Console: Phone Numbers → Buy a Number
   - Select your area code
   - Check "Voice" and "SMS" capabilities
   - Purchase ($1/month)
   - This is your Horizon House main number

4. **Configure Webhook URLs**
   - Click your new number
   - Under "Voice & Fax":
     - Webhook: `http://YOUR-PC-IP:3001/api/pbx/incoming-call`
     - Method: POST
   - Under "Messaging":
     - Webhook: `http://YOUR-PC-IP:3001/api/pbx/incoming-sms`
     - Method: POST
   - Click Save

5. **Add Credentials to Portal**
   - Open: `horizon-portal/backend/.env`
   - Add these lines:
     ```
     TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxx
     TWILIO_AUTH_TOKEN=your_auth_token_here
     TWILIO_PHONE_NUMBER=+15551234567
     ```
   - Save file

6. **Restart Backend Server**
   ```powershell
   cd horizon-portal/backend
   node server.js
   ```

7. **Test Your System**
   - Open: `http://localhost:8080/pbx-dashboard.html`
   - Make a test call
   - Send a test SMS

---

### Option 2: FreePBX (Self-Hosted - Advanced)

**Pros:**
- One-time cost
- Complete control
- No monthly fees (except trunking)
- Enterprise features

**Requirements:**
- Dedicated PC or server (can be old desktop)
- SIP trunk provider (requires monthly service)
- Technical knowledge
- Static IP or VPN setup

**Setup Steps:**

1. **Download FreePBX**
   https://www.freepbx.org/downloads/

2. **Install on Dedicated PC**
   - Create bootable USB
   - Install FreePBX on spare computer
   - Document IP address

3. **Configure SIP Trunk**
   ( providers: Flowroute, VoIP.ms, Bandwidth.com)
   - Create account with provider
   - Add trunk credentials to FreePBX
   - Buy DID (phone number)

4. **Create Extensions**
   - FreePBX Admin → Extensions
   - Create ext 101-105 for staff
   - Generate passwords

5. **Connect to Portal**
   - Configure SIP credentials in portal
   - Update backend server.js with FreePBX IP

---

## Using the PBX System

### Making Calls

1. **Manual Dialing**
   - Open PBX Dashboard
   - Use dialpad to enter number
   - Click "Call" button
   - Call routes through your phone number

2. **Quick Dial from Members**
   - Go to Staff Dashboard
   - Click phone icon next to member
   - Call initiates automatically

3. **Extension Dialing**
   - Enter ext number (101-105)
   - Calls internal extension
   - Free (no minutes used)

### Receiving Calls

1. **Incoming Call Flow**:
   - Someone calls your Horizon House number
   - System answers automatically
   - Plays greeting: "Thank you for calling Horizon House..."
   - Routes to available staff or voicemail

2. **Call Forwarding**:
   - Configure in PBX Settings
   - Forward to mobile after hours
   - Set business hours

### SMS Messaging

1. **Sending SMS**:
   - Open SMS tab in PBX Dashboard
   - Enter phone number
   - Type message
   - Click Send
   - Message sends from your Horizon House number

2. **Receiving SMS**:
   - Texts appear in SMS tab automatically
   - Get notification (coming soon)
   - Reply directly from interface

### Voicemail

1. **Listening to Voicemail**:
   - Click Voicemail tab
   - Blue dot = unread
   - Click Play button
   - Option to transcribe to text (Twilio feature)

2. **Returning Calls**:
   - Click "Call Back" button in voicemail
   - Automatically dials caller
   - Logs interaction

---

## Extension Directory

Default extensions (customize in PBX Settings):

- **101**: Reception/Front Desk
- **102**: Program Director
- **103**: House Manager - Men's Facility
- **104**: House Manager - Women's Facility
- **105**: Accounting/Administration

To add more extensions, see PBX Extensions page.

---

## Features

### Call Recording

All calls automatically recorded (configurable):
- Storage: `backend/uploads/call-recordings/`
- Access: Call Log → Click call → Play Recording
- Retention: 90 days (configurable)
- Legal: Complies with 1-party consent states

### Call Analytics

View statistics:
- Total calls per day/week/month
- Average call duration
- Peak call times
- Missed call rate
- Response time

### IVR (Interactive Voice Response)

Auto-attendant menu:
```
"Thank you for calling Horizon House.
Press 1 for admissions inquiries
Press 2 for current residents
Press 3 for emergencies
Press 0 to speak with reception"
```

Configure in PBX Settings → IVR Menu

### Call Routing Rules

**Business Hours** (9 AM - 5 PM):
- Route to Reception (Ext 101)
- If busy, route to Ext folder 102
- After 30 seconds, voicemail

**After Hours**:
- Play message: "Our offices are currently closed..."
- Option 1: Leave voicemail
- Option 9: Emergency line (forwards to on-call staff mobile)

### Do Not Disturb

Staff can enable DND:
- Status shows "Offline" in dashboard
- Calls route to voicemail
- Can still make outbound calls

---

## Integration with Member Database

### Click-to-Call from Member Records

When viewing member in portal:
- Phone icon appears next to phone number
- Click to instantly call
- Call automatically logs to member record
- Notes field opens for call summary

### SMS from Member Dashboard

- SMS icon next to member phone
- Opens pre-populated SMS window
- Send reminders, check-ins, appointment confirmations
- Full conversation history in member file

---

## Mobile Access

### Using PBX from iPhone/iPad

**Option A: Web Interface**
- Open Safari
- Go to: `http://YOUR-PC-IP:8080/pbx-dashboard.html`
- Bookmark for quick access
- Make calls, send SMS, check voicemail

**Option B: Twilio App**
- Install "Twilio Client SDK" app
- Configure with your account
- Use phone for calls (not data)

**Option B: SIP Client** (for FreePBX)
- Install "Zoiper" or "Linphone" app
- Configure with extension credentials
- Full softphone functionality

---

## Security & Compliance

### HIPAA Compliance

- ✅ Encrypted calls (TLS/SRTP)
- ✅ Secure storage
- ✅ Access logging
- ✅ BAA available from Twilio

### Call Recording Notices

Auto-plays: "This call may be recorded for quality assurance"

### Data Retention

- Call logs: 1 year
- Recordings: 90 days
- SMS: Indefinite (compliance)
- Voicemail: Until deleted

---

## Troubleshooting

### "Call failed to connect"

**Causes:**
- Twilio credentials not configured
- Backend server not running
- Webhook URLs incorrect

**Solutions:**
1. Check `.env` file has correct credentials
2. Restart backend: `node server.js`
3. Verify Twilio phone number is active
4. Test API: `http://localhost:3001/api/pbx/test`

### "SMS not sending"

**Solutions:**
1. Verify SMS enabled on Twilio number
2. Check recipient number format (+1XXXXXXXXXX)
3. Ensure sufficient Twilio balance
4. Check backend logs for errors

### "Can't hear caller"

**Solutions:**
1. Check browser permissions (microphone)
2. Use headset/headphones
3. Verify Twilio client SDK loaded
4. Test with different browser

### "Incoming calls not routing"

**Solutions:**
1. Verify webhook URL in Twilio console
2. Check PC firewall allows port 3001
3. Ensure backend server running
4. Test URL: Use ngrok for temporary public URL

---

## Cost Examples

### Small Office (Twilio)

**Monthly:**
- Phone number: $1
- 200 incoming minutes @ $0.0085 = $1.70
- 100 outgoing minutes @ $0.013 = $1.30
- 50 SMS @ $0.0075 = $0.38
- **Total: ~$4-5/month**

### Medium Usage

**Monthly:**
- Main line + 2 additional numbers: $3
- 1000 minutes mixed: ~$10
- 200 SMS: $1.50
- **Total: ~$15/month**

### With Recording Storage

- Recordings stored in OneDrive (no extra cost)
- Or Twilio storage: $0.0010/min stored

---

## Upgrade Path

### Phase 1 (Current)
- ✅ Basic calling
- ✅ SMS
- ✅ Voicemail
- ✅ Call logging

### Phase 2 (Add Later)
- Call queuing
- Hold music
- Conference calls
- Fax (yes, still needed for medical records)

### Phase 3 (Advanced)
- AI call transcription
- Automated appointment reminders
- Outbound campaign (check-in calls)
- Integration with scheduling

---

## Support Resources

**Twilio Documentation:**
- https://www.twilio.com/docs
- Support: support@twilio.com
- Community Forum
- Live chat in console

**FreePBX Documentation:**
- https://wiki.freepbx.org
- Community Forums
- YouTube tutorials

**This System:**
- See inline help in PBX Dashboard
- Check backend logs: `horizon-portal/backend/logs/`
- Test API endpoints: http://localhost:3001/api/pbx/

---

## Quick Start Checklist

- [ ] Sign up for Twilio account
- [ ] Purchase phone number
- [ ] Add credentials to `.env` file
- [ ] Configure webhooks in Twilio console
- [ ] Restart backend server
- [ ] Test call from PBX dashboard
- [ ] Send test SMS
- [ ] Configure extensions for staff
- [ ] Set up IVR menu (optional)
- [ ] Test incoming call
- [ ] Configure business hours
- [ ] Enable call recording
- [ ] Train staff on using system

---

## Files Created

- `pbx-dashboard.html` - Main PBX interface
- `pbx-settings.html` - Configuration page
- `pbx-extensions.html` - Extension management
- `backend/pbx-api.js` - API endpoints for Twilio
- `backend/.env` - Credentials (create this)

---

**Document Version**: 1.0  
**Last Updated**: March 2026  
**Status**: Ready for production
