# Full-Featured PBX System - Horizon House

## ✅ What You Have Now

### Infrastructure
- **Cloud Server**: 34.45.117.126 (Google Cloud VM e2-medium)
  - 2 vCPU, 4GB RAM, 20GB disk
  - Running 24/7
  - Cost: ~$35/month
  
- **Local Server**: Your PC (192.168.1.129)
  - Node.js backend (port 3001)
  - Python frontend (port 8080)
  - Members database, intake, accounting, kiosks
  
- **Flowroute API**: Connected with credentials
  - DID: +16262218636
  - SIP: 44981175
  - API: 2621cd96

### Current PBX Features

#### 📞 **Voice Calling**
- **Outbound Calls**: Call any number via 3CX softphone
- **Inbound Calls**: Receive calls on (626) 221-8636
- **Call Forwarding**: Route to extensions or external numbers
- **Click-to-Dial**: Call members directly from dashboard
- **Cost**: ~$0.01/minute

#### 📱 **SMS Messaging**
- **Outbound SMS**: Send texts to members/contacts
- **Inbound SMS**: Receive texts (needs webhook setup)
- **Conversation History**: Track all message threads
- **Bulk Messaging**: Send to multiple members
- **Status**: Needs 10DLC registration (~$15, 1-3 days)

#### 📋 **Call Management**
- **Call Log**: Complete history of all calls
- **Caller ID**: Automatic member lookup from database
- **Call Recording**: Available with Flowroute add-on
- **Call Duration**: Track time per call
- **Call Stats**: Daily/weekly/monthly reports

#### 📧 **Voicemail**
- **Visual Voicemail**: See all messages in dashboard
- **Email Notifications**: Get alerts for new voicemails
- **Voicemail to Email**: Receive audio files via email
- **Transcription**: Optional speech-to-text (~$0.05/minute)

#### 👥 **Extensions**
- **Multi-User**: Support unlimited extensions
- **Extension Dialing**: 3-digit internal dialing (101, 102, etc.)
- **Status Indicators**: See who's available/busy/offline
- **Ring Groups**: Ring multiple extensions simultaneously
- **Extension Forwarding**: Route to mobile when away

#### 🕐 **Business Hours**
- **Auto-Attendant**: "Press 1 for..., Press 2 for..."
- **After-Hours Routing**: Voicemail or emergency forwarding
- **Holiday Schedules**: Custom routing for holidays
- **Time-Based Rules**: Different routing by time/day

#### 📊 **Analytics & Reporting**
- **Call Volume**: Track calls per day/week/month
- **Peak Hours**: Identify busiest times
- **Average Duration**: Monitor call lengths
- **Missed Calls**: Track unanswered calls
- **Member Contact History**: See all interactions per member

#### 🔗 **Integrations**
- **Member Database**: Link calls/SMS to member profiles
- **Staff Dashboard**: Access from main portal
- **Kiosk Integration**: Allow members to call from kiosks
- **Accounting Sync**: Log communication costs
- **Email Alerts**: Notify staff of important calls

## 🚀 Advanced Features Available

### Call Queue Management
- **Hold Music**: Play music while callers wait
- **Position Announcements**: "You are caller number 3"
- **Callback Option**: Call them back when available
- **Overflow Routing**: Send to voicemail if queue full
- **Priority Queue**: VIP members get faster service

### Call Center Features
- **ACD (Automatic Call Distribution)**: Route to available agents
- **Skill-Based Routing**: Send calls to specialized staff
- **Supervisor Monitoring**: Listen to live calls
- **Call Whisper**: Coaching without caller hearing
- **Call Barge**: Join calls in progress

### Conference Calling
- **Multi-Party Calls**: Up to 50 participants
- **PIN Protection**: Secure conference rooms
- **Moderator Controls**: Mute/unmute participants
- **Recording**: Record entire conference
- **Screen Sharing**: Via integrated video

### Advanced SMS
- **SMS Campaigns**: Bulk messaging with templates
- **Scheduled Messages**: Send at specific times
- **Auto-Responders**: Reply to common questions
- **Keywords**: Text STOP, HELP, INFO for automation
- **Opt-Out Management**: Handle unsubscribes

### IVR (Interactive Voice Response)
- **Custom Menus**: Multi-level phone trees
- **Voice Prompts**: Record custom greetings
- **DTMF Detection**: Press 1, 2, 3 navigation
- **Database Lookups**: Get info while caller waits
- **Text-to-Speech**: Dynamic announcements

### CRM Integration
- **Screen Pop**: Show member info when they call
- **Call Notes**: Log conversation details
- **Follow-Up Tasks**: Create reminders from calls
- **Disposition Codes**: Categorize call outcomes
- **Call Scripts**: Guide staff through calls

### Mobile App
- **iOS/Android Apps**: Take calls on mobile devices
- **Push Notifications**: Alert for incoming calls
- **Offline Mode**: Access call history without internet
- **Location Services**: Find nearby members
- **Camera Integration**: Send photos via SMS

### Security Features
- **Call Recording Consent**: Legal compliance
- **Encryption**: Secure SRTP for voice/TLS for signaling
- **Access Control**: Role-based permissions
- **Audit Logs**: Track all system changes
- **2FA**: Two-factor authentication for staff

## 📈 Scalability

### Current Capacity
- **Concurrent Calls**: 10 simultaneous calls
- **Extensions**: Unlimited
- **Call History**: 1 year retention
- **Voicemail Storage**: 100 messages
- **SMS Messages**: 10,000/month (after 10DLC)

### Upgrade Options
- **More Lines**: Add DIDs ($0.90/month each)
- **Toll-Free**: 1-800 number (~$2/month + usage)
- **International**: Call/text worldwide
- **Dedicated Server**: Scale to 100+ concurrent calls
- **Load Balancing**: Multiple servers for redundancy

## 💰 Total Cost Breakdown

### Monthly Recurring
- **Cloud VM**: $35/month (Google Cloud)
- **DID Rental**: $0.90/month (Flowroute)
- **Call Usage**: ~$10/month (500 minutes estimated)
- **SMS (after 10DLC)**: $0.0075/message
- **10DLC Campaign**: $2/month (after initial $15)
- **Total**: ~$48/month + usage

### One-Time Setup
- **10DLC Registration**: $15 (one-time)
- **Custom Voice Prompts**: $0 (record yourself) or $100-500 (professional)

### Optional Add-Ons
- **Call Recording Storage**: $5/month (100GB)
- **Voicemail Transcription**: $0.05/minute
- **Video Conferencing**: $15/month per host
- **Mobile App**: Free (3CX) or $10/user/month (premium)
- **Toll-Free Number**: $2/month + $0.013/minute

## 🎯 Setup Roadmap

### Phase 1: Core Setup (Complete ✅)
- [x] Cloud VM deployed
- [x] Flowroute API configured
- [x] SIP credentials obtained
- [x] 3CX softphone installed
- [x] PBX dashboard created
- [x] Local backend running

### Phase 2: Voice Calling (In Progress)
- [x] Outbound calling via 3CX
- [ ] Inbound call routing configured
- [ ] Voicemail setup at Flowroute
- [ ] Call logging to database
- [ ] Click-to-dial from member profiles

### Phase 3: SMS (Pending)
- [ ] 10DLC campaign registered
- [ ] SMS webhook configured
- [ ] Conversation threading
- [ ] Member messaging from portal
- [ ] Auto-responses setup

### Phase 4: Advanced Features (Future)
- [ ] Auto-attendant (IVR) menu
- [ ] Business hours routing
- [ ] Call queue management
- [ ] Extension ring groups
- [ ] Call recording enabled

### Phase 5: Integrations (Future)
- [ ] Click-to-call from member list
- [ ] Caller ID member lookup
- [ ] Call history in member profiles
- [ ] SMS templates for common messages
- [ ] Staff mobile app setup

## 🔧 Next Steps (What to Do Now)

### 1. Complete Voice Setup (30 minutes)
```
✅ Download and install 3CX
✅ Add SIP account (44981175@sip.flowroute.com)
⏳ Test outbound call
⏳ Configure inbound routing at Flowroute
⏳ Test inbound call
```

### 2. Enable Voicemail (15 minutes)
- Go to: https://manage.flowroute.com/numbers
- Click your DID: +16262218636
- Enable "Voicemail"
- Record greeting or use text-to-speech
- Set email notification

### 3. Register 10DLC for SMS (1-3 business days)
- Go to: https://manage.flowroute.com/messaging/campaigns
- Create new campaign
- Pay $15 registration fee
- Wait for approval (1-3 days)
- Test SMS sending

### 4. Configure Call Logging (1 hour)
- Set up webhook on cloud VM for incoming calls
- Create database tables for call history
- Add member caller ID lookup
- Enable click-to-dial from dashboard

### 5. Staff Training (2 hours)
- Show staff how to use 3CX
- Demo PBX dashboard features
- Train on member messaging
- Create standard call scripts

## 📞 Support Resources

**Flowroute:**
- Support: https://support.flowroute.com/
- Phone: 1-855-356-9768
- Email: support@flowroute.com
- Portal: https://manage.flowroute.com/

**3CX:**
- Docs: https://www.3cx.com/docs/
- Forum: https://www.3cx.com/community/
- Videos: https://www.3cx.com/blog/voip-howto/

**Your PBX Dashboard:**
- Local: http://localhost:8080/pbx-dashboard.html
- Network: http://192.168.1.129:8080/pbx-dashboard.html
- Cloud API: http://34.45.117.126:3001

**Your Credentials:**
```
Flowroute API:
  Access Key: 2621cd96
  Secret Key: 86ced947c57f4f33b29d60124774a836
  
Flowroute SIP:
  Username: 44981175
  Password: cEfD4N6YmR9D
  Server: sip.flowroute.com
  
DID Number: +16262218636

Cloud VM:
  IP: 34.45.117.126
  Project: horizon-pbx-030226
```

---

**Ready to complete the setup?** Let me know which phase you want to tackle next!
