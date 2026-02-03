# Horizon House Portal - Project Status

**Last Updated:** February 3, 2026 6:20 PM  
**Developer:** rmars + GitHub Copilot  
**Active Branch:** main  
**Deployment Status:** ✅ Live

---

## 🚀 Deployment URLs

- **Backend API:** https://horizon-portal-backend-production-3532.up.railway.app
- **Frontend:** GitHub repository auto-deploys via Vercel
- **Repositories:**
  - Backend: https://github.com/rmarsnpas/horizon-portal-backend.git
  - Frontend: https://github.com/rmarsnpas/horizon-portal-frontend.git

---

## 📋 Current Status

### Working Features
✅ Member sign-in/out kiosks (men's & women's with gender filtering)  
✅ Staff dashboard with member status monitoring  
✅ Member portal with messaging system  
✅ Sobriety counter with milestone celebrations  
✅ Application processing system  
✅ Brochure viewer with print functionality  
✅ Image uploads in messaging  
✅ Conversation naming and management  

### Known Issues
- ⚠️ Railway filesystem is ephemeral (uploaded images don't persist across deploys)
- ⚠️ Excel column names use `\r\n` (CRLF) - must use exact format

### Technical Debt
- Consider migrating to cloud storage (S3/Cloudinary) for images
- Consider database migration from Excel to MongoDB/PostgreSQL
- Add proper authentication/JWT instead of simple session storage

---

## 🎯 Next Priorities

### Immediate (This Week)
- [ ] Test brochure print functionality on all browsers
- [ ] Monitor message system for any issues
- [ ] Clean up any unused files in workspace

### Short-term (This Month)
- [ ] Add push notifications for new messages
- [ ] Implement typing indicators in chat
- [ ] Add message search functionality
- [ ] Create admin panel for message moderation

### Long-term (Future)
- [ ] Cloud storage integration for images
- [ ] Database migration
- [ ] Mobile app version
- [ ] Voice/video messaging

---

## 📝 Recent Changes (Last 5 Sessions)

### Feb 3, 2026 - Brochure Viewer Updates
- ✅ Updated to new PDF: `brochure 012726.pdf`
- ✅ Added print button with JavaScript functionality
- ✅ Cleaned up old brochure files (brochure.pdf, brochure.html, brochure-print.html)
- 📦 Deployed: Commit `c5ca041`

### Feb 1, 2026 - Sobriety Counter
- ✅ Added days sober counter to member dashboard
- ✅ Implemented milestone celebrations with confetti
- ✅ 15 milestone checkpoints (30 days through 3 years)
- 📦 Deployed: Commit `bc19bd2`

### Feb 1, 2026 - Messaging System Complete
- ✅ Image upload support
- ✅ Status-based color coding
- ✅ Conversation naming/renaming
- ✅ Read receipts and unread counts
- 📦 Deployed: Multiple commits

### Jan 28, 2026 - Messaging System Foundation
- ✅ Created messaging REST API
- ✅ Built chat UI (876 lines)
- ✅ 1-on-1 and group conversations
- 📦 Deployed: Commits `4e02e3d`, `a95912a`

### Jan 26, 2026 - Kiosk Fixes
- ✅ Fixed gender filtering on kiosks
- ✅ Updated column mapping to use `\r\n`
- ✅ Changed timezone from EST to PDT
- 📦 Deployed: Commit `a0466a4`

---

## 🏗️ Architecture Overview

### Backend (Node.js + Express)
- **Port:** 3001
- **Server File:** `backend/server.js` (1,643 lines)
- **Database:** Excel (`members.xlsx`) + JSON files
- **Hosting:** Railway (auto-deploy from GitHub)

### Frontend (HTML/CSS/JavaScript)
- **Static files** served from backend
- **No build process** - vanilla HTML/CSS/JS
- **Session Storage** for auth (memberId, memberName)

### Data Storage
```
backend/
├── members.xlsx          # Member database (Excel)
├── messages.json         # Chat conversations & messages
├── sign-inout-logs.json  # Sign in/out tracking
├── contact_submissions.json
├── pending_applications.json
└── uploads/
    └── messages/         # Uploaded chat images (ephemeral on Railway)
```

---

## 🔑 Important Technical Details

### Excel Column Mapping (CRITICAL!)
```javascript
const colMap = {
    id: 'ID',
    firstName: 'FIRST\r\nNAME',      // Note: \r\n not \n
    lastName: 'LAST\r\nNAME',        // Note: \r\n not \n
    gender: 'M/F',
    soberDate: 'SOBER\r\nDATE',      // Note: \r\n not \n
    status: 'STATUS'
};
```

### Status Codes
- **1** = Active (Green)
- **2** = Pending (Blue)
- **3** = Inactive (Red)
- **4/5** = Special status (Underlined Green)

### Timezone
- **PDT (UTC-8)** for curfew calculations

### API Base URL
```javascript
const API_URL = 'https://horizon-portal-backend-production-3532.up.railway.app';
```

---

## 🛠️ Common Commands

### Local Development
```bash
# Start backend server
cd c:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal\backend
node server.js
# Runs on http://localhost:3001

# Open frontend files directly in browser or use Live Server
```

### Git Workflow
```bash
# Check status
git status

# Add and commit
git add .
git commit -m "Description of changes"
git push

# Both repos auto-deploy on push
```

### Testing API Endpoints
```bash
# Get all members
curl https://horizon-portal-backend-production-3532.up.railway.app/api/members

# Get specific member
curl https://horizon-portal-backend-production-3532.up.railway.app/api/getMember?id=0101
```

---

## 📂 Key Files & Locations

### Portal Files
```
horizon-portal/
├── PROJECT_STATUS.md         ← YOU ARE HERE (read first!)
├── DEVELOPMENT_LOG.md        ← Historical record
├── backend/
│   ├── server.js             ← Main Express server
│   ├── members.xlsx          ← Member database
│   ├── messages.json         ← Chat data
│   └── package.json          ← Dependencies
├── members/
│   ├── dashboard.html        ← Member home with sobriety counter
│   ├── chat.html             ← Messaging interface
│   └── sign-inout.html       ← Sign in/out
├── kiosk-men.html            ← Men's kiosk
├── kiosk-women.html          ← Women's kiosk
└── staff-intake-portal.html  ← Staff dashboard
```

### Main Website Files (Parent Directory)
```
index_files/
├── index.html                ← Main website
├── brochure-viewer.html      ← Brochure with print button
├── brochure 012726.pdf       ← Latest brochure PDF
├── application.html          ← Public application form
└── horizon-portal/           ← Portal subdirectory
```

---

## 🐛 Troubleshooting Quick Reference

### Messages not loading
1. Check console: `F12` → Console tab
2. Verify API_URL in chat.html
3. Check Railway logs: https://railway.app/dashboard
4. Confirm `messages.json` exists in backend/

### Kiosk rejecting members
1. Verify gender field in Excel (`M/F` column)
2. Check column names use `\r\n`
3. Confirm member status is 1 (Active)

### Sobriety counter showing 0
1. Check `SOBER\r\nDATE` column in Excel
2. Verify date format is valid
3. Check getMember API includes sober date
4. Console log errors: `F12` → Console

---

## 💡 Session Handoff Notes

### What's Working Well
- Messaging system is stable and feature-complete
- Kiosks properly filtering by gender
- Sobriety counter with milestones is engaging
- Brochure viewer with print is deployed

### What Needs Attention
- Nothing urgent
- Consider testing print function across browsers

### Blocked/Waiting On
- Nothing currently blocked

---

## 📞 Quick Context for New Sessions

When starting a new session, read this file first, then:
1. Check **Next Priorities** section
2. Review **Recent Changes** to see what was just done
3. Check **Known Issues** for any blockers
4. Review **Session Handoff Notes** for context

**Standard greeting to get back in sync:**
> "Continue where we left off" 
> or
> "What's next on the priority list?"

---

*This file should be updated at the END of each work session*
*Keep it current - this is your context anchor across sessions and computers*
