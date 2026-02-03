# Horizon House Portal

A comprehensive web application for managing sober living house operations including member management, kiosk sign-in/out systems, messaging, and staff dashboards.

---

## 🚀 Quick Start

### Prerequisites
- Node.js 16+
- Excel file with member data (`members.xlsx`)

### Local Development

```bash
# 1. Navigate to backend directory
cd horizon-portal/backend

# 2. Install dependencies (first time only)
npm install

# 3. Start the server
node server.js

# Server runs on http://localhost:3001
```

### Access the Portal

**Kiosks:**
- Men's Kiosk: `kiosk-men.html`
- Women's Kiosk: `kiosk-women.html`
- General Sign-in: `kiosk-signin.html`

**Member Portal:**
- Dashboard: `members/dashboard.html`
- Messages: `members/chat.html`
- Sign In/Out: `members/sign-inout.html`

**Staff:**
- Staff Dashboard: `staff-intake-portal.html`

---

## 📁 Project Structure

```
horizon-portal/
├── README.md                  ← Quick start guide (this file)
├── PROJECT_STATUS.md          ← Current status (read first each session!)
├── DEVELOPMENT_LOG.md         ← Historical development notes
│
├── backend/
│   ├── server.js              ← Express server (Port 3001)
│   ├── package.json           ← Node dependencies
│   ├── members.xlsx           ← Member database (Excel)
│   ├── messages.json          ← Chat data
│   ├── sign-inout-logs.json   ← Sign in/out tracking
│   └── uploads/messages/      ← Uploaded images
│
├── members/
│   ├── dashboard.html         ← Member landing page
│   ├── chat.html              ← Messaging system
│   ├── sign-inout.html        ← Member sign in/out
│   └── member-status.html     ← Status board
│
├── intake/
│   ├── start-intake.html      ← Intake flow start
│   ├── member-agreement.html
│   ├── emergency-contact.html
│   └── [other intake forms]
│
├── kiosk-men.html             ← Men's kiosk
├── kiosk-women.html           ← Women's kiosk
├── kiosk-signin.html          ← General kiosk
└── staff-intake-portal.html   ← Staff dashboard
```

---

## 🔧 Technology Stack

- **Backend:** Node.js + Express.js
- **Frontend:** Vanilla HTML/CSS/JavaScript (no framework)
- **Database:** Excel (members.xlsx) + JSON files
- **File Uploads:** Multer
- **Email:** SendGrid (optional)
- **Deployment:** Railway (backend), Vercel (frontend)

---

## 🌐 API Endpoints

### Member Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/members` | Get all members (optional `?gender=M/F`) |
| GET | `/api/getMember?id=X` | Get single member by ID |

### Sign In/Out System
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/signInOut/current` | Get currently signed out members |
| POST | `/api/signInOut/out` | Sign a member out |
| POST | `/api/signInOut/in` | Sign a member in |
| GET | `/api/signInOut/history` | Get sign in/out history |

### Messaging System
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/messages/conversations?memberId=X` | Get user's conversations |
| GET | `/api/messages/:conversationId?memberId=X` | Get messages |
| POST | `/api/messages/send` | Send a message |
| POST | `/api/messages/conversation` | Create conversation |
| PATCH | `/api/messages/conversation/:id` | Update conversation name |
| POST | `/api/messages/upload-image` | Upload image |

---

## 📊 Excel Database Format

**Important:** Column headers use `\r\n` (CRLF line endings)!

### Required Columns
| Column Name | Format | Description |
|-------------|--------|-------------|
| `ID` | String | Unique member ID |
| `FIRST\r\nNAME` | String | First name |
| `LAST\r\nNAME` | String | Last name |
| `M/F` | M or F | Gender |
| `SOBER\r\nDATE` | Date | Sobriety start date |
| `STATUS` | 1-5 | Member status code |

### Status Codes
- **1** = Active (Green)
- **2** = Pending (Blue)
- **3** = Inactive (Red)
- **4/5** = Special status

---

## 🚀 Deployment

### Backend (Railway)
```bash
# Automatically deploys from GitHub
# Repository: rmarsnpas/horizon-portal-backend
# URL: https://horizon-portal-backend-production-3532.up.railway.app
```

### Frontend (Vercel/GitHub Pages)
```bash
# Automatically deploys from GitHub
# Repository: rmarsnpas/horizon-portal-frontend
```

### Manual Deploy
```bash
# Push to GitHub - auto-deploys
git add .
git commit -m "Description of changes"
git push
```

---

## 🛠️ Configuration

### Environment Variables (Backend)
```env
PORT=3001
SENDGRID_API_KEY=your_sendgrid_api_key_here
```

### Frontend API Configuration
Update `API_URL` in HTML files:
```javascript
// Local development
const API_URL = 'http://localhost:3001';

// Production
const API_URL = 'https://horizon-portal-backend-production-3532.up.railway.app';
```

---

## 🧪 Testing

### Test Locally
```bash
# Start server
cd backend
node server.js

# Test in browser
# Open any HTML file with Live Server or directly in browser
```

### Test API Endpoints
```bash
# PowerShell
Invoke-RestMethod -Uri http://localhost:3001/api/members

# cURL
curl http://localhost:3001/api/members
```

---

## 🐛 Common Issues

### Issue: "Gender field not found"
**Solution:** Excel columns must use `\r\n` exactly: `FIRST\r\nNAME`

### Issue: "Images not displaying after deployment"
**Cause:** Railway filesystem is ephemeral  
**Solution:** Use cloud storage (S3, Cloudinary) for production images

### Issue: "CORS errors"
**Solution:** Check CORS config in `server.js` includes your domain

### Issue: "Messages not loading"
1. Check browser console (F12)
2. Verify API_URL is correct
3. Check Railway logs
4. Ensure `messages.json` exists

---

## 📚 Additional Documentation

- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Current status & priorities (READ FIRST!)
- **[DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md)** - Historical development notes
- **[backend/EMAIL_SETUP.md](backend/EMAIL_SETUP.md)** - SendGrid configuration

---

## 🤝 Contributing / Development Workflow

### Starting a New Session
1. Read `PROJECT_STATUS.md` first
2. Check "Next Priorities" section
3. Pull latest changes: `git pull`
4. Start working

### Ending a Session
1. Commit your changes: `git add . && git commit -m "Session: Brief summary"`
2. Push to GitHub: `git push`
3. Update `PROJECT_STATUS.md` with what was completed
4. Update "Session Handoff Notes" section

### When Context is Lost
Say: **"Continue where we left off"** - I'll read `PROJECT_STATUS.md` and resume

---

## 📞 Support & Links

**Project Location:**  
`c:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\horizon-portal`

**Repositories:**
- Backend: https://github.com/rmarsnpas/horizon-portal-backend.git
- Frontend: https://github.com/rmarsnpas/horizon-portal-frontend.git

**Production:**
- Backend API: https://horizon-portal-backend-production-3532.up.railway.app
- Frontend: [Vercel/GitHub Pages URL]

---

## ⚖️ License

Private project for Horizon House Sober Living

---

*For current status and what to work on next, see [PROJECT_STATUS.md](PROJECT_STATUS.md)*
