# 3CX Softphone Setup - Horizon House

## 📱 Download & Install

**Download 3CX Windows App:**
https://www.3cx.com/phone-system/windows-voip-phone/

Or use alternatives:
- **Zoiper**: https://www.zoiper.com/
- **Linphone**: https://www.linphone.org/

## ⚙️ Configuration Settings

### Your SIP Account Credentials

```
Account Name: Horizon House
Username: 44981175
Password: cEfD4N6YmR9D
Domain/Server: sip.flowroute.com
Port: 5060 (UDP) or 5061 (TCP/TLS)
Transport: UDP (try first) or TCP
```

## 🔧 Step-by-Step Setup (3CX)

### 1. Open 3CX App
- Launch 3CX after installation
- Click the **"+"** button or **"Add Account"**

### 2. Select Account Type
- Choose **"Generic SIP Account"** or **"Advanced Settings"**

### 3. Enter Account Details

**Basic Settings:**
```
Extension/Username: 44981175
Password: cEfD4N6YmR9D
```

**Advanced Settings:**
```
SIP Server: sip.flowroute.com
Outbound Proxy: (leave blank)
Port: 5060
Transport: UDP
```

### 4. Audio Settings
- **Microphone**: Select your mic/headset
- **Speaker**: Select your audio output
- **Ringtone**: Choose ringtone device

### 5. Save & Register
- Click **"Save"** or **"OK"**
- Wait for status to show **"Registered"** (green indicator)

## ✅ Testing

### Test Outbound Call
1. Type any 10-digit number in dialpad
2. Example: `8185551234`
3. Click **"Call"** or press Enter
4. Call should connect!

### Test Audio
- Make sure you can hear and be heard
- Adjust volume if needed
- Test microphone/speaker settings

### Test Inbound Call
- Have someone call: **(626) 221-8636**
- Your 3CX should ring
- Click **"Answer"**

## 🔧 Troubleshooting

### Can't Register (Red Status)

**Check Credentials:**
- Username: `44981175` (no spaces)
- Password: `cEfD4N6YmR9D` (case-sensitive)
- Server: `sip.flowroute.com` (no http://)

**Try Different Transport:**
- Change from UDP to TCP
- Or try port 5061 with TLS

**Firewall Issue:**
- Allow ports 5060-5061 (SIP)
- Allow ports 10000-20000 (RTP audio)
- Disable VPN temporarily to test

### Can Make Calls But No Audio

**Audio Device:**
- Check microphone is selected and working
- Check speaker/headset is selected
- Test with Windows Sound settings

**Firewall/NAT:**
- Enable STUN: `stun.flowroute.com`
- Enable ICE if available
- Check router has SIP ALG disabled

**Codec Issues:**
- Enable G.711 (mu-law and a-law)
- Disable G.729 if present
- Prefer uncompressed codecs

### Calls Drop After 30 Seconds

**NAT Keepalive:**
- Enable "NAT Keepalive" in settings
- Set to 30 seconds
- Enable "Register Periodically"

**Session Timer:**
- Enable SIP Session Timer
- Set to 1800 seconds
- Enable Min-SE

### Poor Call Quality

**Check Internet:**
- Need at least 100 Kbps per call
- Run speed test: speedtest.net
- Close bandwidth-heavy apps

**QoS Settings:**
- Enable QoS in router
- Prioritize VoIP traffic
- Set DSCP/TOS values

**Audio Settings:**
- Enable echo cancellation
- Enable noise reduction
- Disable audio enhancements in Windows

## 📱 Alternative Softphones

### Zoiper Configuration
```
Account Name: Horizon House
Account Type: SIP
Host: sip.flowroute.com
Username: 44981175
Password: cEfD4N6YmR9D
Authentication: Username + Password
Outbound Proxy: (blank)
```

### Linphone Configuration
```
Username: 44981175
SIP Domain: sip.flowroute.com
Password: cEfD4N6YmR9D
Transport: UDP or TCP
```

### MicroSIP (Lightweight)
Download: https://www.microsip.org/
```
Account Name: Horizon
SIP Server: sip.flowroute.com
SIP User: 44981175
Password: cEfD4N6YmR9D
Domain: sip.flowroute.com
```

## 🎧 Hardware Recommendations

### Budget (~$30)
- **Logitech H390** USB Headset
- Good audio quality
- Noise-canceling mic
- USB plug-and-play

### Mid-Range (~$80)
- **Jabra Evolve 40** USB Headset
- Excellent audio
- Professional quality
- Comfortable for all-day use

### Premium (~$150)
- **Poly Voyager 4320** UC
- Wireless Bluetooth + USB
- Active noise cancellation
- Multi-device pairing

### Desk Phone Style (~$100)
- **Yealink T46U** IP Phone
- Physical desk phone
- Color screen
- PoE or AC power
- Configure with same SIP credentials

## 📞 Making Calls

### Dial Format
```
Local (same area code): 5551234
Long distance: 8185551234
International: 011441234567890
```

### Speed Dial
- Save frequent numbers in contacts
- Click contact to dial instantly
- Import contacts from CSV

### Call Features
- **Hold**: Put call on hold
- **Transfer**: Transfer to another number
- **Mute**: Mute your microphone
- **Keypad**: Send DTMF tones during call
- **Add Call**: Conference in another person

## 🔔 Receiving Calls

### Incoming Call Routing
Currently: All calls to (626) 221-8636 → Your SIP account

To change routing:
1. Go to: https://manage.flowroute.com/numbers
2. Click your DID: +16262218636
3. Under "Call Routing" select:
   - Forward to SIP URI: `44981175@sip.flowroute.com`
   - Or configure IVR/voicemail
4. Save changes

### Multiple Devices
- Register same account on multiple devices
- All will ring simultaneously
- First to answer gets the call
- Others show "Call Ended"

## 💾 Backup Configuration

Save these settings:
```
HORIZON HOUSE PBX - SIP ACCOUNT
================================
Username: 44981175
Password: cEfD4N6YmR9D
Server: sip.flowroute.com
DID: +16262218636
Port: 5060 (UDP) or 5061 (TCP)
```

Keep a copy in:
- Password manager
- Printed on paper (secure location)
- Shared with IT person

## 📞 Support

**Flowroute SIP Support:**
- Email: support@flowroute.com
- Phone: 1-855-356-9768
- Portal: https://manage.flowroute.com/

**3CX Support:**
- Docs: https://www.3cx.com/docs/
- Forum: https://www.3cx.com/community/

**Test Your Setup:**
- Call yourself: (626) 221-8636
- Echo test: Call a friend and check audio
- Voicemail test: Let call go to voicemail

---

**Ready to make calls!** 📞
