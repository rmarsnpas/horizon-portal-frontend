# Horizon House Portal - Development Log

**Project:** Horizon House Member Portal  
**Period:** January 2026 - February 2026  
**Developer:** GitHub Copilot + User (rmars)

---

## Project Overview

The Horizon House Portal is a web application for managing sober living house operations, including:
- Member sign-in/out kiosks (gender-specific)
- Staff dashboard and member status monitoring
- Member portal with messaging, sobriety tracking
- Application processing system

**Technology Stack:**
- **Backend:** Node.js + Express (Port 3001)
- **Frontend:** HTML/CSS/JavaScript
- **Database:** Excel (members.xlsx) + JSON files
- **Deployment:** Railway (backend), GitHub Pages (frontend)
- **Repositories:**
  - Backend: https://github.com/rmarsnpas/horizon-portal-backend.git
  - Frontend: https://github.com/rmarsnpas/horizon-portal-frontend.git

---

## Recent Development Sessions

### Session 1: Kiosk System Fixes (January 2026)

#### Issues Identified
1. Kiosks rejecting male members with "This kiosk is for men only" error
2. Gender field not returned by `/api/getMember` endpoint
3. Column names in Excel using `\r\n` (CRLF) instead of `\n`
4. Gender filtering not working on status boards
5. Timezone using EST instead of PDT

#### Changes Made

**Backend (server.js):**
- Added `gender: 'M/F'` to colMap object
- Updated all column name references to use `\r\n`:
  - `'FIRST\r\nNAME'`, `'LAST\r\nNAME'`, `'SOBER\r\nDATE'`
- Changed timezone from EST (UTC-5) to PDT (UTC-8) for overdue calculations
- Added gender field to getMember API response
- Enabled static file serving: `app.use(express.static(path.join(__dirname, '..')));`

**Frontend:**
- `kiosk-men.html`: Added gender filtering to loadStatusBoard() using `/api/members?gender=M`
- `kiosk-women.html`: Added gender filtering to loadStatusBoard() using `/api/members?gender=F`
- `members/member-status.html`: Fixed column name lookups to handle `\r\n` variants

**Git Commits:**
- `a0466a4` - Fix kiosks: add gender filtering, fix column mapping, change timezone to PDT, enable static files

---

### Session 2: Data Cleanup & Deployment

#### Changes Made
- Cleared all sign-in/out history to start fresh
- Deployed all fixes to Railway production
- Fixed member status board showing "unknown" names

**Files Modified:**
- `sign-inout-logs.json`: Reset to `{ "current": [], "history": [] }`

**Git Commits:**
- Backend: `4e02e3d` - Add messaging system with REST API endpoints
- Frontend: `a3ecbfa` - Various fixes

---

### Session 3: Messaging System Implementation

#### Features Added
1. **Real-time messaging** between members and staff
2. **1-on-1 and group chat** support
3. **Conversation management** with naming
4. **Unread message indicators**
5. **Read receipts**

#### Backend Implementation (server.js)

**New Files:**
- `backend/messages.json`: Data store for conversations and messages
  ```json
  {
    "conversations": [],
    "messages": []
  }
  ```

**New Constants:**
```javascript
const MESSAGES_PATH = path.join(__dirname, 'messages.json');
const UPLOADS_DIR = path.join(__dirname, 'uploads', 'messages');
```

**New API Endpoints:**

1. `GET /api/messages/conversations?memberId=X`
   - Returns all conversations for a member with unread counts
   - Includes last message preview

2. `GET /api/messages/:conversationId?memberId=X`
   - Returns all messages in a conversation
   - Automatically marks messages as read

3. `POST /api/messages/send`
   - Send a message to a conversation
   - Creates new conversation if needed
   - Supports text and images

4. `POST /api/messages/conversation`
   - Create a new conversation
   - Checks for existing conversations with same participants

5. `PATCH /api/messages/conversation/:conversationId`
   - Update conversation name
   - Validates member is a participant

6. `POST /api/messages/upload-image`
   - Upload image for message
   - 5MB file size limit
   - Supports JPEG, PNG, GIF, WebP

**Helper Functions:**
```javascript
function loadMessages()  // Load messages from JSON
function saveMessages(data)  // Save messages to JSON
```

**CORS Configuration Update:**
```javascript
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
```

#### Frontend Implementation (members/chat.html)

**New File:** `horizon-portal/members/chat.html` (691 lines)

**Features:**
- Two-panel layout: Conversations list + Message thread
- Real-time polling (refreshes every 3 seconds)
- Image upload with preview
- Conversation creation modal
- Member selection with status-based color coding
- Conversation renaming
- Responsive design

**Key Functions:**
```javascript
loadConversations()  // Load and display conversation list
selectConversation(id, name)  // Switch to a conversation
loadMessages()  // Load messages for current conversation
sendMessage()  // Send text/image message
handleImageSelect(event)  // Handle image file selection
clearImageSelection()  // Remove selected image
showNewMessageModal()  // Show member selection dialog
createConversation()  // Create new conversation
editConversationName()  // Rename conversation
```

**Status-Based Color Coding:**
- Status 1: Green (`#28a745`)
- Status 2: Blue (`#007bff`)
- Status 3: Red (`#dc3545`)
- Status 4/5: Underlined green

**Dashboard Integration:**
- Added "Messages" card to `members/dashboard.html`
- Stores memberId and memberName in sessionStorage

**Git Commits:**
- Backend: `4e02e3d` - Add messaging system with REST API endpoints
- Frontend: `a95912a` - Add messaging feature: chat UI
- Frontend: `732c2e4` - Fix chat: update API URL to Railway
- Backend: `71a9cf9` - Add conversation naming: PATCH endpoint
- Frontend: `bf6978c` - Add conversation naming UI
- Backend: `02b812b` - Add detailed logging to conversation rename
- Frontend: `9394189` - Add detailed error logging
- Backend: `5b3b63e` - Fix CORS: add PATCH method
- Frontend: `896199e` - Add status-based color coding
- Backend: `03df510` - Add image/photo upload support
- Frontend: `5b4052d` - Add image/photo upload UI

---

### Session 4: Sobriety Counter & Milestone Celebrations

#### Features Added
- **Days sober counter** on member dashboard
- **Milestone celebrations** with animations
- **Confetti effects** for major achievements

#### Implementation (members/dashboard.html)

**New UI Component:**
```html
<div class="sobriety-card" id="sobrietyCard">
    <h3>🌟 Your Sobriety Journey 🌟</h3>
    <div class="days-counter" id="daysCounter">0</div>
    <div class="days-label">Days Strong</div>
    <div class="sober-date" id="soberDate"></div>
    <div id="milestoneDisplay"></div>
</div>
```

**Milestone Schedule:**
- 30 days - 🎉 "One Month Strong!"
- 60 days - 🌟 "Two Months of Freedom!"
- 90 days - 🏆 "Three Months Achievement!"
- 120 days - 💪 "Four Months of Strength!"
- 150 days - 🎊 "Five Months Milestone!"
- 180 days - ⭐ "Half Year Celebration!"
- 210 days - 🎯 "Seven Months Victory!"
- 240 days - 🔥 "Eight Months Strong!"
- 270 days - 👑 "Nine Months Champion!"
- 300 days - 💎 "Ten Months Diamond!"
- 330 days - 🌈 "Eleven Months Rainbow!"
- 365 days - 🎆 "ONE YEAR - Amazing Achievement!"
- 730 days - 🏅 "TWO YEARS - Incredible Journey!"
- 1095 days - 👏 "THREE YEARS - Outstanding!"

**Confetti Animation:**
- Triggers on major milestones: 30, 90, 180, 365, 730, 1095 days
- 50 colored confetti pieces
- Falls from top to bottom with rotation
- Auto-removes after 6 seconds

**Key Functions:**
```javascript
displaySobrietyInfo(soberDate)  // Calculate and display days sober
checkMilestone(days)  // Check if current day is a milestone
showConfetti()  // Display confetti animation
```

**Data Source:**
- Reads from Excel column: `SOBER\r\nDATE`
- Calculates difference between current date and sober date
- Updates on dashboard load

**Git Commits:**
- Frontend: `bc19bd2` - Add sobriety counter with milestone celebrations

---

## File Structure

```
horizon-portal/
├── backend/
│   ├── server.js (1,643 lines) - Main Express server
│   ├── applications.js - Application processing
│   ├── messages.json - Chat data store
│   ├── sign-inout-logs.json - Sign in/out tracking
│   ├── members.xlsx - Member database
│   ├── package.json - Node dependencies
│   └── uploads/
│       └── messages/ - Uploaded chat images
├── members/
│   ├── dashboard.html - Member landing page with sobriety counter
│   ├── chat.html (876 lines) - Messaging interface
│   ├── member-status.html - Member status board
│   └── sign-inout.html - Sign in/out interface
├── kiosk-men.html - Men's kiosk
├── kiosk-women.html - Women's kiosk
├── kiosk-signin.html - General sign-in kiosk
└── admin-sync.html - Admin synchronization
```

---

## API Endpoints Reference

### Member Management
- `GET /api/members` - Get all members (optional `?gender=M/F` filter)
- `GET /api/getMember?id=X` - Get single member by ID

### Sign In/Out System
- `GET /api/signInOut/current` - Get currently signed out members
- `POST /api/signInOut/out` - Sign a member out
- `POST /api/signInOut/in` - Sign a member in
- `GET /api/signInOut/history` - Get sign in/out history

### Messaging System
- `GET /api/messages/conversations?memberId=X` - Get user's conversations
- `GET /api/messages/:conversationId?memberId=X` - Get conversation messages
- `POST /api/messages/send` - Send a message
- `POST /api/messages/conversation` - Create conversation
- `PATCH /api/messages/conversation/:conversationId` - Update conversation name
- `POST /api/messages/upload-image` - Upload image

---

## Data Models

### Message Object
```javascript
{
    id: "timestamp-string",
    conversationId: "conversation-id",
    senderId: "member-id",
    senderName: "First Last",
    text: "message text",
    imageUrl: "/uploads/messages/filename.jpg" | null,
    timestamp: "ISO-8601-datetime",
    readBy: ["member-id1", "member-id2"]
}
```

### Conversation Object
```javascript
{
    id: "timestamp-string",
    participants: ["member-id1", "member-id2"],
    isGroup: true|false,
    name: "Conversation Name" | null,
    createdAt: "ISO-8601-datetime"
}
```

### Sign In/Out Record
```javascript
{
    id: "unique-id",
    memberId: "member-id",
    memberName: "First Last",
    date: "YYYY-MM-DD",
    timeOut: "HH:MM AM/PM",
    timeIn: "HH:MM AM/PM" | null,
    destination: "destination text",
    signOutTimestamp: "ISO-8601-datetime",
    signInTimestamp: "ISO-8601-datetime" | null,
    curfewViolation: true|false
}
```

---

## Excel Column Mapping

**Important:** Excel columns use `\r\n` (CRLF) line endings!

```javascript
const colMap = {
    id: 'ID',
    firstName: 'FIRST\r\nNAME',
    lastName: 'LAST\r\nNAME',
    gender: 'M/F',
    soberDate: 'SOBER\r\nDATE',
    status: 'STATUS'
    // Add other columns as needed
};
```

**Status Codes:**
- 1 = Active (Green)
- 2 = Pending (Blue)
- 3 = Inactive (Red)
- 4/5 = Special status (Underlined Green)

---

## Configuration

### Environment Variables
```
PORT=3001
SENDGRID_API_KEY=<api-key>
```

### Railway Deployment
- **URL:** https://horizon-portal-backend-production-3532.up.railway.app
- **Auto-deploys** from GitHub master branch
- **Static files** served from backend

### Local Development
```bash
# Backend
cd backend
node server.js
# Runs on http://localhost:3001

# Frontend
# Open HTML files directly in browser or use live server
```

---

## Known Issues & Resolutions

### Issue: CORS blocking PATCH requests
**Resolution:** Added 'PATCH' to allowed methods in CORS config (Commit: 5b3b63e)

### Issue: Column names not matching
**Resolution:** Changed all column references from `\n` to `\r\n` (Commit: a0466a4)

### Issue: Railway filesystem ephemeral
**Note:** Uploaded images may not persist on Railway. Consider using cloud storage (S3, Cloudinary) for production.

---

## Future Enhancements (Not Yet Implemented)

### Potential Features
- [ ] Push notifications for new messages
- [ ] Voice messages
- [ ] Video calls
- [ ] File attachments (PDFs, documents)
- [ ] Message search
- [ ] Message deletion
- [ ] Conversation archiving
- [ ] Typing indicators
- [ ] Online status indicators
- [ ] Cloud storage for images (S3/Cloudinary)
- [ ] Database migration (MongoDB/PostgreSQL)
- [ ] User authentication with JWT
- [ ] Admin panel for message moderation

---

## Troubleshooting Guide

### Messages not loading
1. Check browser console for errors
2. Verify API_URL points to correct server
3. Check Railway logs for backend errors
4. Ensure messages.json exists and is readable

### Images not displaying
1. Verify uploads/messages directory exists
2. Check file permissions
3. Confirm image URL format: `/uploads/messages/filename.jpg`
4. For Railway: Images won't persist across deployments

### Sobriety counter not showing
1. Verify member has `SOBER\r\nDATE` in Excel
2. Check date format is valid
3. Ensure getMember API returns sober date
4. Check browser console for JavaScript errors

### Kiosk errors
1. Verify gender field is returned by API
2. Check column mapping uses `\r\n`
3. Confirm timezone is PDT (UTC-8)
4. Verify member ID format matches Excel

---

## Development Commands

### Git Workflow
```bash
# Backend
cd backend
git add .
git commit -m "Description"
git push

# Frontend
cd ..
git add .
git commit -m "Description"
git push
```

### Testing Locally
```bash
# Start backend server
cd backend
node server.js

# Test endpoints
curl http://localhost:3001/api/members
curl http://localhost:3001/api/getMember?id=0101
```

---

## Contact & Support

**Project Location:**
`c:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal`

**Repositories:**
- Backend: https://github.com/rmarsnpas/horizon-portal-backend.git
- Frontend: https://github.com/rmarsnpas/horizon-portal-frontend.git

---

*Last Updated: February 1, 2026*
*Total Development Time: ~6 hours*
*Lines of Code Added: ~2,500+*
