# Extension Routing Setup Guide

## Two Options for Extension Routing

---

## Option 1: Simple Extension Routing (Current System)

**What you get:**
- ✅ Basic extension routing (101, 102, 103, etc.)
- ✅ Forward to cell phones/desk phones
- ✅ Business hours routing
- ✅ Simple IVR menu
- ⚠️ No actual desk phones (forwards to existing phones)
- ⚠️ Manual configuration (edit code files)

**Setup Time:** 30 minutes

### Quick Setup:

1. **Edit Extension Configuration:**
   - Open: `pbx/backend/pbx-extensions.js`
   - Update phone numbers for each extension
   - Set business hours
   - Configure voicemail emails

2. **Configure Flowroute Webhook:**
   - Login to Flowroute dashboard
   - Go to: Numbers → Select your number
   - Set Inbound Route to: `https://your-vm-ip:3001/api/pbx/incoming-call`

3. **Test:**
   - Call your main number: (626) 221-8636
   - Press 1 → Routes to Intake Coordinator's phone
   - Press 2 → Routes to House Manager's phone
   - Press 0 → Routes to Operator

**Example Call Flow:**
```
Caller dials (626) 221-8636
    ↓
Hears: "Thank you for calling Horizon House. Press 1 for admissions..."
    ↓
Presses 1
    ↓
System forwards call to Intake Coordinator's cell phone
    ↓
If no answer after 20 seconds → Goes to voicemail
```

---

## Option 2: FreePBX (Professional System)

**What you get:**
- ✅ Real extension-to-extension calling
- ✅ Actual desk phones (if you buy IP phones)
- ✅ Web GUI for easy configuration
- ✅ Advanced IVR with recorded greetings
- ✅ Call queues (hold music, position announcements)
- ✅ Ring groups (simultaneous/sequential ringing)
- ✅ Integrated voicemail system
- ✅ Call recording built-in
- ✅ Professional features (call parking, paging, conferencing)

**Setup Time:** 2-3 hours

### Ideal for:

- **Multiple staff members in same building**
- **Need internal extension calling** (dial 102 from any phone)
- **Want professional hold/greeting messages**
- **Need call queues** for busy times
- **Want dedicated desk phones** (not just cell forwarding)

---

## Comparison

| Feature | Current System + Extensions | FreePBX |
|---------|---------------------------|---------|
| Extension routing | ✅ Via forwarding | ✅ True extensions |
| IVR menu | ✅ Basic | ✅ Advanced |
| Desk phones | ❌ Forwards to existing phones | ✅ Can use IP desk phones |
| Internal calling | ❌ | ✅ Extension-to-extension |
| Web GUI | ❌ Edit code | ✅ Full admin panel |
| Call queues | ❌ | ✅ With hold music |
| Setup complexity | Simple | Moderate |
| Maintenance | Edit config files | Web interface |
| Cost | $0 extra | $0 (just IP phones if wanted) |

---

## Recommendation by Setup

### Small Team (1-3 people, mostly mobile)
→ **Use Option 1** (Simple Extension Routing)
- Edit `pbx-extensions.js` to forward to cell phones
- Quick setup, works great for forwarding
- No additional hardware needed

### Office Team (4+ people, shared location)
→ **Use Option 2** (FreePBX)
- Get real desk phones ($50-200 each)
- Staff can dial extension-to-extension
- Professional call handling
- Worth the setup time

---

## Hardware Options (If Going FreePBX Route)

### Budget IP Phones ($50-80 each):
- **Yealink T42S** - $70
- **Grandstream GXP2602** - $65
- **Fanvil X4U** - $60

### Mid-Range ($100-150):
- **Yealink T46S** - $120
- **Grandstream GXP2614** - $110

### Premium ($200+):
- **Yealink T54W** - $180
- **Cisco SPA504G** - $200

### Cordless Options:
- **Yealink W56P** DECT - $150 (wireless, works anywhere in building)
- **Grandstream DP750** - $180 (base + handsets)

---

## Current System Extension Implementation

### Step 1: Configure Extensions

Edit [pbx/backend/pbx-extensions.js](../backend/pbx-extensions.js):

```javascript
const EXTENSIONS = {
    '101': {
        name: 'Admin Office',
        forwardTo: '+16265551001',  // ← Put your actual phone here
        voicemail: true,
        email: 'admin@horizonhouse.com'
    },
    // Add more extensions...
};
```

### Step 2: Update Server

Add to your `server.js`:

```javascript
const extensions = require('./pbx-extensions');

// Handle incoming call webhook from Flowroute
app.post('/api/pbx/incoming-call', async (req, res) => {
    const { from, to } = req.body;
    
    // Get IVR response
    const response = extensions.handleIncomingCall(from, to);
    
    // Return TwiML/FlowXML for call routing
    res.send(generateCallRoutingXML(response));
});

// Handle IVR digit press
app.post('/api/pbx/ivr-response', async (req, res) => {
    const { digit, caller } = req.body;
    
    const routing = extensions.handleIVROption(digit, caller);
    res.send(generateCallRoutingXML(routing));
});
```

### Step 3: Configure Flowroute

1. Login to https://manage.flowroute.com
2. Navigate to: **Numbers** → **[Your Number]**
3. Set **Inbound Route**:
   - Route Type: HTTP
   - URL: `https://34.45.117.126:3001/api/pbx/incoming-call`
   - Method: POST

### Step 4: Test

```bash
# Call your main number
# Press different digits and verify routing

# Check logs:
docker logs -f your-backend-container
```

---

## FreePBX Extension Implementation

### Step 1: Install FreePBX
Follow [FREEPBX_INSTALLATION.md](FREEPBX_INSTALLATION.md)

### Step 2: Create Extensions Via Web GUI

1. **Open FreePBX:** http://34.45.117.126
2. **Navigate to:** Applications → Extensions → Add Extension
3. **Create each extension:**
   - Extension 101 - Admin
   - Extension 102 - Intake  
   - Extension 103 - Manager
   - Etc.

### Step 3: Configure IVR Via Web GUI

1. **Navigate to:** Applications → IVR
2. **Record greeting** or upload audio file
3. **Set digit mappings:**
   - 1 → Extension 102
   - 2 → Extension 103
   - 0 → Ring Group (all staff)

### Step 4: Set Inbound Route

1. **Navigate to:** Connectivity → Inbound Routes
2. **DID:** 6262218636
3. **Destination:** IVR → Main Menu

### Step 5: Connect Desk Phones (Optional)

For each phone:
1. Find phone's IP (check phone screen or router)
2. Login to phone's web interface
3. Set SIP account:
   - Extension: 101
   - Password: [from FreePBX]
   - Server: 34.45.117.126

---

## Which Should You Choose?

### Choose Simple Extension Routing If:
- ✅ Small team (1-3 people)
- ✅ Everyone uses cell phones already
- ✅ Just need call forwarding + basic IVR
- ✅ Want quick setup (30 min)
- ✅ Don't need internal extension calling

### Choose FreePBX If:
- ✅ Larger team (4+ people)
- ✅ Want dedicated desk phones
- ✅ Need extension-to-extension calling
- ✅ Want advanced call queues
- ✅ Need professional features (call parking, paging, conferencing)
- ✅ Want easy web-based management
- ✅ Have time for setup (2-3 hours)

---

## Quick Decision Helper

**Answer these questions:**

1. **Do you have a physical office where staff work?**
   - Yes, same location → FreePBX
   - No, remote/mobile → Simple routing

2. **Do you want desk phones?**
   - Yes → FreePBX (required)
   - No → Simple routing is fine

3. **Do staff need to call each other internally?**
   - Yes → FreePBX
   - No → Simple routing works

4. **How many incoming calls per day?**
   - < 10 calls → Simple routing is fine
   - 10-50 calls → Either works
   - 50+ calls → FreePBX preferred (call queues)

5. **How technical are you?**
   - Comfortable with code → Either works
   - Prefer GUI → FreePBX
   - Want simplest → Simple routing

---

## Next Steps

### For Simple Extension Routing:
```bash
# 1. Update extension config
code pbx/backend/pbx-extensions.js

# 2. Add routing to your server
code horizon-portal/backend/server.js

# 3. Configure Flowroute webhook
# (login to Flowroute dashboard)

# 4. Test by calling your number
```

### For FreePBX:
```bash
# Follow the full installation guide
code pbx/docs/FREEPBX_INSTALLATION.md

# Or just tell me: "install freepbx"
```

---

**What's your setup?** 
- How many staff members?
- Same office or remote?
- Need desk phones or using cell phones?

This will help determine which option is best for you.
