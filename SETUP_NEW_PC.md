# Setting Up Another PC to Work on Horizon House Project

**Goal:** Get another computer fully synced with all project context so GitHub Copilot knows everything.

---

## 📋 Quick Setup (10 Minutes)

### Step 1: Install Required Software

1. **Install VS Code**
   - Download: https://code.visualstudio.com/
   - Install with default settings

2. **Install Git**
   - Download: https://git-scm.com/download/win
   - Install with default settings

3. **Install Node.js** (for backend development)
   - Download: https://nodejs.org/ (LTS version)
   - Install with default settings

4. **Install GitHub Copilot in VS Code**
   - Open VS Code
   - Click Extensions (Ctrl+Shift+X)
   - Search "GitHub Copilot"
   - Click Install
   - Sign in with your GitHub account

---

### Step 2: Clone the Repository

**Open PowerShell or Terminal on the new PC:**

```powershell
# Navigate to where you want the project
cd "C:\Users\[YourUsername]\Documents"

# Clone the frontend repository
git clone https://github.com/rmarsnpas/horizon-portal-frontend.git

# Navigate into the project
cd horizon-portal-frontend
```

---

### Step 3: Open in VS Code

```powershell
# Open VS Code in this folder
code .
```

---

### Step 4: Tell Copilot to Read the Documentation

**In VS Code, open the Copilot chat and type:**

```
Read the file horizon-portal/PROJECT_STATUS.md and tell me what I should work on next
```

**Copilot will:**
- ✅ Read all the current status
- ✅ See what features are working
- ✅ Know what's been done recently
- ✅ Tell you the next priorities
- ✅ Be fully in sync with this PC!

---

### Step 5: (Optional) Set Up Backend

**If you also need the backend on the new PC:**

```powershell
# In a separate folder, clone backend
cd ..
git clone https://github.com/rmarsnpas/horizon-portal-backend.git

# Navigate to backend
cd horizon-portal-backend/backend

# Install dependencies
npm install

# Start the server
node server.js
```

---

## 🔄 Workflow for Working on Multiple PCs

### On PC #1 (Current PC):
```powershell
# At the end of your work session:
git add -A
git commit -m "Description of what you did"
git push

# Update PROJECT_STATUS.md before pushing!
```

### On PC #2 (New PC):
```powershell
# At the start of your work session:
cd path/to/horizon-portal-frontend
git pull

# Then in VS Code Copilot chat:
# "Continue where we left off"
```

**Copilot will read PROJECT_STATUS.md and know exactly what's been done!**

---

## 📂 Key Files for Copilot Context

When starting on a new PC, these files give Copilot all the context:

1. **horizon-portal/PROJECT_STATUS.md** ⭐ MOST IMPORTANT
   - Current status
   - Recent changes
   - Next priorities
   - What's working/broken

2. **horizon-portal/README.md**
   - Technical setup
   - API endpoints
   - File structure
   - Common commands

3. **horizon-portal/DEVELOPMENT_LOG.md**
   - Historical record
   - Why decisions were made
   - Implementation details

4. **PROJECT_REVIEW.md**
   - Project organization analysis
   - Cleanup guidance

---

## 💬 What to Say to Copilot on New PC

### First time opening project:
```
Read horizon-portal/PROJECT_STATUS.md and summarize the current state of the project
```

### When resuming work:
```
Continue where we left off
```

### When you want to work on something specific:
```
I want to work on [feature]. What should I know from PROJECT_STATUS.md?
```

### If Copilot seems lost:
```
Please read these files for context:
- horizon-portal/PROJECT_STATUS.md
- horizon-portal/README.md
- horizon-portal/DEVELOPMENT_LOG.md
```

---

## 🔧 Troubleshooting

### Problem: Copilot doesn't remember what was done
**Solution:** Ask it to read PROJECT_STATUS.md explicitly:
```
Read horizon-portal/PROJECT_STATUS.md
```

### Problem: Files are out of sync between PCs
**Solution:** Always pull before starting work:
```powershell
git pull
```

### Problem: Merge conflicts
**Solution:** 
```powershell
# If you edited same file on both PCs:
git stash              # Save your changes
git pull               # Get latest from GitHub
git stash pop          # Reapply your changes
# Fix conflicts manually if needed
```

### Problem: Backend won't start
**Solution:**
```powershell
cd backend
npm install           # Reinstall dependencies
node server.js        # Try again
```

---

## ✅ Verification Checklist

**After setup on new PC, verify:**

- [ ] VS Code installed and GitHub Copilot working
- [ ] Repository cloned successfully
- [ ] Can see all files in VS Code
- [ ] PROJECT_STATUS.md opens and looks complete
- [ ] Copilot responds when you ask it to read PROJECT_STATUS.md
- [ ] Git commands work (`git status`)

**Optional (for backend work):**
- [ ] Node.js installed (`node --version`)
- [ ] Backend repository cloned
- [ ] Backend starts without errors (`node server.js`)

---

## 🎯 Best Practice Workflow

### Before Starting Work (Any PC):
1. Open project in VS Code
2. Run `git pull` in terminal
3. Ask Copilot: "Continue where we left off"
4. Start working

### After Finishing Work (Any PC):
1. Save all files
2. Update PROJECT_STATUS.md if you made significant changes
3. Run `git add -A`
4. Run `git commit -m "What you did"`
5. Run `git push`

**This keeps both PCs perfectly in sync!**

---

## 🌟 Pro Tips

1. **Use OneDrive/Dropbox Sync**
   - The project is already in your OneDrive folder
   - Other PC just needs to sync OneDrive
   - No git needed, instant sync!
   - ⚠️ But still use Git for version control

2. **Keep PROJECT_STATUS.md Updated**
   - This is your "save game" file
   - Update it at the end of each session
   - Copilot reads this to know everything

3. **Create Bookmarks**
   - Bookmark the GitHub repos on both PCs
   - Easy access to deployment status

4. **Use VS Code Settings Sync**
   - Settings → Turn on Settings Sync
   - Syncs extensions, settings across all PCs

---

## 📞 Quick Reference

**GitHub Repositories:**
- Frontend: https://github.com/rmarsnpas/horizon-portal-frontend.git
- Backend: https://github.com/rmarsnpas/horizon-portal-backend.git

**Live Deployment:**
- Backend API: https://horizon-portal-backend-production-3532.up.railway.app
- Frontend: Auto-deploys from GitHub

**Project Location on This PC:**
`C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files`

**Magic Phrase for Copilot:**
> "Continue where we left off"

---

*Last Updated: February 3, 2026*
