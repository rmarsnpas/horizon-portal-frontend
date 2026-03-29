// ==========================================
// PBX DATA STORAGE (JSON-based)
// ==========================================

const fs = require('fs');
const path = require('path');

const CALL_LOG_PATH = path.join(__dirname, 'call_log.json');
const VOICEMAIL_PATH = path.join(__dirname, 'voicemails.json');
const EXTENSIONS_PATH = path.join(__dirname, 'extensions.json');

// ==========================================
// CALL LOG
// ==========================================

function loadCallLog() {
    try {
        if (fs.existsSync(CALL_LOG_PATH)) {
            const data = fs.readFileSync(CALL_LOG_PATH, 'utf8');
            return JSON.parse(data);
        }
    } catch (error) {
        console.error('Error loading call log:', error);
    }
    return [];
}

function saveCallLog(callLog) {
    try {
        fs.writeFileSync(CALL_LOG_PATH, JSON.stringify(callLog, null, 2));
        return true;
    } catch (error) {
        console.error('Error saving call log:', error);
        return false;
    }
}

// ==========================================
// VOICEMAILS
// ==========================================

function loadVoicemails() {
    try {
        if (fs.existsSync(VOICEMAIL_PATH)) {
            const data = fs.readFileSync(VOICEMAIL_PATH, 'utf8');
            return JSON.parse(data);
        }
    } catch (error) {
        console.error('Error loading voicemails:', error);
    }
    return [];
}

function saveVoicemail(voicemails) {
    try {
        fs.writeFileSync(VOICEMAIL_PATH, JSON.stringify(voicemails, null, 2));
        return true;
    } catch (error) {
        console.error('Error saving voicemails:', error);
        return false;
    }
}

// ==========================================
// EXTENSIONS
// ==========================================

function loadExtensions() {
    try {
        if (fs.existsSync(EXTENSIONS_PATH)) {
            const data = fs.readFileSync(EXTENSIONS_PATH, 'utf8');
            return JSON.parse(data);
        }
    } catch (error) {
        console.error('Error loading extensions:', error);
    }
    
    // Default extensions
    return [
        { number: '101', name: 'Reception Desk', status: 'available', forwardTo: null },
        { number: '102', name: 'Program Director', status: 'available', forwardTo: null },
        { number: '103', name: 'House Manager - Men\'s', status: 'available', forwardTo: null },
        { number: '104', name: 'House Manager - Women\'s', status: 'available', forwardTo: null },
        { number: '105', name: 'Accounting', status: 'offline', forwardTo: null }
    ];
}

function saveExtensions(extensions) {
    try {
        fs.writeFileSync(EXTENSIONS_PATH, JSON.stringify(extensions, null, 2));
        return true;
    } catch (error) {
        console.error('Error saving extensions:', error);
        return false;
    }
}

module.exports = {
    loadCallLog,
    saveCallLog,
    loadVoicemails,
    saveVoicemail,
    loadExtensions,
    saveExtensions
};
