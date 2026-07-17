# FreePBX Installation Guide - Horizon House

## Overview

Installing FreePBX on your Google Cloud VM (34.45.117.126) using Docker for easy deployment alongside your existing services.

---

## System Requirements

**Your VM Specs:**
- ✅ 2 vCPU (minimum 1 required)
- ✅ 4GB RAM (minimum 2GB required)
- ✅ 20GB disk (minimum 10GB required)
- ✅ Ubuntu/Linux OS

**Ports Required:**
- `80` - FreePBX Web GUI (HTTP)
- `443` - FreePBX Web GUI (HTTPS)
- `5060` - SIP signaling (UDP)
- `5061` - SIP signaling TLS (TCP)
- `10000-20000` - RTP media (UDP)

---

## Installation Steps

### Step 1: Connect to Your VM

```bash
# From your local machine
gcloud compute ssh your-vm-instance-name --zone=your-zone

# Or use SSH directly
ssh username@34.45.117.126
```

### Step 2: Install Docker (if not already installed)

```bash
# Update system
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (optional, avoids sudo)
sudo usermod -aG docker $USER

# Verify installation
docker --version
```

### Step 3: Open Firewall Ports

```bash
# On Google Cloud Console, create firewall rules:
# Rule 1: freepbx-web
gcloud compute firewall-rules create freepbx-web \
  --allow tcp:80,tcp:443 \
  --source-ranges 0.0.0.0/0 \
  --description "FreePBX Web Interface"

# Rule 2: freepbx-sip
gcloud compute firewall-rules create freepbx-sip \
  --allow udp:5060,tcp:5061 \
  --source-ranges 0.0.0.0/0 \
  --description "FreePBX SIP Signaling"

# Rule 3: freepbx-rtp
gcloud compute firewall-rules create freepbx-rtp \
  --allow udp:10000-20000 \
  --source-ranges 0.0.0.0/0 \
  --description "FreePBX RTP Media"
```

### Step 4: Deploy FreePBX Container

```bash
# Create persistent directories
mkdir -p ~/freepbx/data
mkdir -p ~/freepbx/logs

# Run FreePBX container
docker run -d \
  --name freepbx \
  --restart=unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -p 5060:5060/udp \
  -p 5061:5061/tcp \
  -p 10000-20000:10000-20000/udp \
  -e ADMIN_PASSWORD="YourSecurePassword123!" \
  -e ENABLE_FAIL2BAN=TRUE \
  -e RTP_START=10000 \
  -e RTP_FINISH=20000 \
  -v ~/freepbx/data:/data \
  -v ~/freepbx/logs:/var/log \
  tiredofit/freepbx:latest

# Check status
docker ps
docker logs freepbx
```

**Note:** Initial setup takes 5-10 minutes. Watch logs with:
```bash
docker logs -f freepbx
```

### Step 5: Access FreePBX Web Interface

1. Open browser: `http://34.45.117.126`
2. Default credentials:
   - Username: `admin`
   - Password: `YourSecurePassword123!` (what you set above)

---

## Configure Flowroute SIP Trunk

### Step 1: Add Trunk in FreePBX

1. **Navigate to:** Connectivity → Trunks → Add Trunk → Add SIP (chan_pjsip) Trunk

2. **General Settings:**
   - Trunk Name: `Flowroute`
   - Outbound CallerID: `6262218636`
   - CID Options: Allow Any CID

3. **pjsip Settings Tab:**
   
   **General:**
   - Username: `44981175` (your Flowroute Tech Prefix)
   - Secret: `2621cd96` (your Flowroute Secret Key)
   - Authentication: `Outbound`
   - Registration: `Send`
   - SIP Server: `us-east-nj.sip.flowroute.com`
   - SIP Server Port: `5060`
   - Context: `from-pstn`
   
   **Advanced:**
   - From Domain: `us-east-nj.sip.flowroute.com`
   - From User: `44981175`
   - Match (Permit): `0.0.0.0/0` (or specific Flowroute IPs)

4. **Click Submit and Apply Config**

### Step 2: Create Outbound Route

1. **Navigate to:** Connectivity → Outbound Routes → Add Outbound Route

2. **Route Settings:**
   - Route Name: `External`
   - Route Position: `1`
   - Trunk Sequence: Select `Flowroute`

3. **Dial Patterns:**
   - Add pattern: `NXXNXXXXXX` (10-digit US numbers)
   - Add pattern: `1NXXNXXXXXX` (11-digit with 1)
   - Add pattern: `011.` (international)

4. **Click Submit and Apply Config**

### Step 3: Create Inbound Route

1. **Navigate to:** Connectivity → Inbound Routes → Add Incoming Route

2. **Route Settings:**
   - Description: `Main Line`
   - DID Number: `6262218636`
   - Set Destination: (choose where calls go - extension, IVR, ring group, etc.)

3. **Click Submit and Apply Config**

---

## Create Extensions for Staff

### Add Extensions

1. **Navigate to:** Applications → Extensions → Add Extension → Add New Chan_PJSIP Extension

2. **Extension Settings (repeat for each staff member):**
   
   **Extension 101 - Admin:**
   - User Extension: `101`
   - Display Name: `Admin Office`
   - Secret: `HorizonAdmin101!`
   - Find Me/Follow Me: Enabled
   
   **Extension 102 - Intake Coordinator:**
   - User Extension: `102`
   - Display Name: `Intake Coordinator`
   - Secret: `HorizonIntake102!`
   
   **Extension 103 - House Manager:**
   - User Extension: `103`
   - Display Name: `House Manager`
   - Secret: `HorizonManager103!`

3. **Configure each extension:**
   - Enable voicemail
   - Set email for voicemail notifications
   - Configure direct DID routing if needed

4. **Click Submit and Apply Config**

---

## Setup IVR (Auto Attendant)

### Create IVR Menu

1. **Navigate to:** Applications → IVR → Add IVR

2. **IVR Settings:**
   - Name: `Main Menu`
   - Announcement: Record or upload greeting:
     - "Thank you for calling Horizon House. Press 1 for admissions, Press 2 for current residents, Press 3 for accounting, or stay on the line for the operator."
   
3. **IVR Entries:**
   - `1` → Extension 102 (Intake Coordinator)
   - `2` → Ring Group (all staff)
   - `3` → Extension (accounting)
   - `t` (timeout) → Extension 101 (Admin)
   - `i` (invalid) → Extension 101 (Admin)

4. **Update Inbound Route:**
   - Go back to your inbound route
   - Set Destination: IVR → Main Menu

5. **Click Submit and Apply Config**

---

## Configure Voicemail

### Global Voicemail Settings

1. **Navigate to:** Settings → Voicemail Admin → Settings

2. **Settings:**
   - Email Subject: `New voicemail from {VM_CALLERID}`
   - Email Body: Include transcription if available
   - Email Attachment: Yes (include audio file)
   - Delete Voicemail: No (keep on server)

3. **Per-Extension Settings:**
   - Navigate to each extension
   - Enable voicemail
   - Enter email address
   - Set voicemail PIN
   - Enable email notification

---

## Integration with Current System

### Option 1: Keep Both Systems

**FreePBX handles:**
- Staff extensions (101, 102, 103, etc.)
- Inbound call routing and IVR
- Professional voicemail system
- Extension-to-extension calling

**Your custom PBX handles:**
- Click-to-dial from member dashboard
- SMS integration
- Direct API calls for simple tasks
- Member database integration

### Option 2: Use FreePBX API

**Install FreePBX API module:**
```bash
# SSH into FreePBX container
docker exec -it freepbx /bin/bash

# Enable API
fwconsole ma downloadinstall api
fwconsole reload
```

**Make calls from your dashboard via FreePBX:**
```javascript
// Example: Originate call from extension 101 to member
const axios = require('axios');

async function makeCall(extension, phoneNumber) {
  const response = await axios.post('http://34.45.117.126/api/call', {
    channel: `PJSIP/${extension}`,
    application: 'Dial',
    data: `PJSIP/${phoneNumber}@flowroute`,
    timeout: 30000
  }, {
    auth: {
      username: 'admin',
      password: 'your-api-token'
    }
  });
  return response.data;
}
```

---

## Security Recommendations

### 1. Change Default Passwords
```bash
# Access FreePBX admin panel
# Navigate to: Admin → Administrators
# Change admin password immediately
```

### 2. Enable Fail2Ban
Already enabled in Docker container with `ENABLE_FAIL2BAN=TRUE`

### 3. Restrict SIP Access
```bash
# In FreePBX: Settings → Asterisk SIP Settings
# Add Flowroute IPs to permit list:
# us-east-nj.sip.flowroute.com
# Deny all other IPs
```

### 4. Enable HTTPS
```bash
# Get free SSL certificate
docker exec -it freepbx /bin/bash
fwconsole certificates --import
fwconsole setting HTTPSONLY 1
```

### 5. Regular Updates
```bash
# Update FreePBX modules
docker exec -it freepbx fwconsole ma upgradeall
docker exec -it freepbx fwconsole reload
```

---

## Monitoring & Maintenance

### Check System Status
```bash
# Container status
docker ps
docker stats freepbx

# FreePBX status
docker exec -it freepbx fwconsole pm2 --list

# Asterisk status
docker exec -it freepbx asterisk -rvvv
```

### View Logs
```bash
# Container logs
docker logs -f freepbx

# Asterisk logs
docker exec -it freepbx tail -f /var/log/asterisk/full

# Call detail records
docker exec -it freepbx cat /var/log/asterisk/cdr-csv/Master.csv
```

### Backup
```bash
# Backup FreePBX data
tar -czf freepbx-backup-$(date +%Y%m%d).tar.gz ~/freepbx/data

# To restore
tar -xzf freepbx-backup-YYYYMMDD.tar.gz -C ~/freepbx/
docker restart freepbx
```

---

## Troubleshooting

### Trunk Not Registering
```bash
# Check trunk status
docker exec -it freepbx asterisk -rx "pjsip show registrations"

# Test connectivity to Flowroute
docker exec -it freepbx ping us-east-nj.sip.flowroute.com

# Check credentials in trunk settings
# Verify Flowroute Tech Prefix and Secret Key
```

### No Audio on Calls
```bash
# Check RTP ports are open
sudo ufw status
# Or check Google Cloud firewall rules

# Verify NAT settings in FreePBX
# Navigate to: Settings → Asterisk SIP Settings
# Chan PJSIP Settings → External Address: 34.45.117.126
```

### Can't Access Web Interface
```bash
# Check container is running
docker ps

# Check port 80 is listening
docker exec -it freepbx netstat -tlnp | grep :80

# Check Google Cloud firewall allows port 80
```

### Extension Can't Register
```bash
# In FreePBX Asterisk CLI
docker exec -it freepbx asterisk -rvvv

# Monitor registration attempts
pjsip set logger on

# Check extension settings match client settings
# Verify username, secret, and server address
```

---

## Connecting Softphones

### 3CX Setup (Windows/Mac/Mobile)

**Extension 101 Settings:**
- Account Name: `Horizon House - Admin`
- Extension: `101`
- ID: `101`
- Password: `HorizonAdmin101!`
- Server: `34.45.117.126`
- Port: `5060`
- Transport: `UDP`

### Zoiper Setup (Alternative)

**Account Settings:**
- Username: `101`
- Password: `HorizonAdmin101!`
- Domain: `34.45.117.126`
- Outbound Proxy: (leave blank)

---

## Cost Breakdown

**Infrastructure:**
- Google Cloud VM: ~$35/month (existing)
- FreePBX Software: FREE

**Calling Costs (via Flowroute):**
- Inbound: $0.0068/minute
- Outbound: $0.012/minute
- SMS: $0.0042/message

**Example Monthly Cost:**
- 500 inbound minutes: $3.40
- 300 outbound minutes: $3.60
- 100 SMS: $0.42
- **Total: ~$42.42/month** (including VM)

---

## Next Steps

1. ✅ Install FreePBX (this guide)
2. ⬜ Configure Flowroute trunk
3. ⬜ Create staff extensions
4. ⬜ Setup IVR menu
5. ⬜ Record professional greetings
6. ⬜ Test internal calling (extension to extension)
7. ⬜ Test outbound calling
8. ⬜ Test inbound calling
9. ⬜ Configure voicemail
10. ⬜ Train staff on phone system

---

## Support Resources

- **FreePBX Wiki:** https://wiki.freepbx.org
- **FreePBX Forums:** https://community.freepbx.org
- **Flowroute Docs:** https://developer.flowroute.com
- **Asterisk Docs:** https://docs.asterisk.org

---

## Quick Reference

**FreePBX Web Interface:**
- URL: http://34.45.117.126
- Username: admin
- Password: [your-password]

**Flowroute Credentials:**
- Tech Prefix: 44981175
- Secret Key: 2621cd96
- DID: +1 (626) 221-8636

**Key Commands:**
```bash
# Access container
docker exec -it freepbx /bin/bash

# Asterisk CLI
asterisk -rvvv

# Apply config changes
fwconsole reload

# Restart FreePBX
docker restart freepbx
```

---

Last Updated: March 12, 2026
