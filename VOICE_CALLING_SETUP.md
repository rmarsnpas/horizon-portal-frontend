# Voice Calling Setup - Horizon House PBX

## Quick Start: Make & Receive Calls Now

### Step 1: Install SIP Softphone

**Download 3CX (Recommended):**
- Windows: https://www.3cx.com/phone-system/windows-voip-phone/
- Or use: Zoiper (https://www.zoiper.com/) or Linphone (https://www.linphone.org/)

### Step 2: Configure Softphone

Open the softphone and add a SIP account with these settings:

```
Account Name: Horizon House PBX
Username: 44981175
Password: cEfD4N6YmR9D
Domain/Server: sip.flowroute.com
Transport: UDP or TCP (try UDP first)
```

**3CX Specific Settings:**
1. Open 3CX app
2. Click "+" to add account
3. Select "Generic SIP Account"
4. Enter the credentials above
5. Click "Save"
6. Status should show "Registered" (green)

### Step 3: Configure Incoming Calls at Flowroute

1. Go to: https://manage.flowroute.com/numbers
2. Click on your number: **+16262218636**
3. Under "Call Routing" section:
   - Select **"Forward to SIP URI"**
   - Enter: `44981175@sip.flowroute.com`
   - Click "Save"

This routes incoming calls to your SIP account (the softphone app).

### Step 4: Test Calls

**Make Outbound Call:**
1. Open 3CX
2. Type a phone number (include area code)
3. Click "Call" or press Enter
4. Call should connect!

**Receive Inbound Call:**
1. Have someone call: **(626) 221-8636**
2. Your 3CX should ring
3. Click "Answer"

## Advanced: Multiple Extensions

To add more staff phones:

1. **Get more SIP credentials from Flowroute:**
   - Go to: https://manage.flowroute.com/accounts/preferences/sip/
   - Create additional SIP users

2. **Set up PBX forwarding rules:**
   - Main reception: Forward to extension 101
   - Auto-attendant: Use Flowroute's IVR settings
   - After-hours: Forward to voicemail

## Troubleshooting

**Can't Register:**
- Check username/password are correct (case-sensitive)
- Try changing Transport to TCP if UDP fails
- Make sure firewall isn't blocking ports 5060-5061

**Can't Make Calls:**
- Verify account shows "Registered"
- Include full 10-digit number with area code
- Try format: 1-626-555-1234

**Can't Receive Calls:**
- Verify call routing at Flowroute points to your SIP URI
- Make sure softphone is running and registered
- Check that computer audio/microphone work

**Poor Call Quality:**
- Check internet connection speed (need 100kbps per call)
- Enable "Echo Cancellation" in softphone
- Try different codec (prefer G.711)

## Cost

**Flowroute Pricing:**
- Outbound calls: ~$0.01/minute (USA)
- Inbound calls: ~$0.0085/minute (USA)
- DID rental: $0.90/month
- No contracts or minimums

**Monthly estimate for 500 minutes:**
- Outbound: $5
- Inbound: $4.25
- DID: $0.90
- **Total: ~$10.15/month**

## Your Credentials (Keep Secure)

```
SIP Username: 44981175
SIP Password: cEfD4N6YmR9D
SIP Server: sip.flowroute.com
DID Number: +16262218636
```

## Next Steps

1. ✅ Install softphone (3CX)
2. ✅ Add SIP account with credentials above
3. ✅ Configure call routing at Flowroute
4. ⏳ Test outbound call
5. ⏳ Test inbound call
6. ⏳ Add to other staff computers
7. ⏳ Set up voicemail at Flowroute (optional)
8. ⏳ Configure business hours routing (optional)

---

**Support:**
- Flowroute: https://support.flowroute.com/
- 3CX: https://www.3cx.com/docs/
- PBX Dashboard: http://localhost:8080/pbx-dashboard.html
