// ==========================================
// FLOWROUTE SIP TRUNK INTEGRATION FOR PBX
// ==========================================

const axios = require('axios');
const { loadCallLog, saveCallLog, loadVoicemails, saveVoicemail } = require('./pbx-storage');

// Flowroute API Configuration
const FLOWROUTE_ACCESS_KEY = process.env.FLOWROUTE_ACCESS_KEY || '';
const FLOWROUTE_SECRET_KEY = process.env.FLOWROUTE_SECRET_KEY || '';
const FLOWROUTE_API_BASE = 'https://api.flowroute.com/v2.1';
const FLOWROUTE_VOICE_API = 'https://api.flowroute.com/v2';

// Create auth header
const flowrouteAuth = Buffer.from(`${FLOWROUTE_ACCESS_KEY}:${FLOWROUTE_SECRET_KEY}`).toString('base64');

// ==========================================
// OUTBOUND CALLING
// ==========================================

/**
 * Make outbound call via Flowroute Voice API
 * @param {string} to - Destination phone number (E.164 format)
 * @param {string} from - Your Flowroute DID number
 * @param {string} extension - Internal extension making call (optional)
 * @param {string} staffPhone - Phone number to call first (for click-to-call bridge)
 */
async function makeOutboundCall(to, from, extension = null, staffPhone = null) {
    try {
        // Format numbers to E.164
        const toNumber = formatE164(to);
        const fromNumber = formatE164(from);
        
        console.log(`Initiating call from ${fromNumber} to ${toNumber}${staffPhone ? ` (bridging via ${staffPhone})` : ''}`);
        
        // For browser-based calling, we use a call bridge:
        // 1. System calls the staff member first
        // 2. When staff answers, system bridges to destination
        
        const callData = {
            to: staffPhone ? formatE164(staffPhone) : toNumber,
            from: fromNumber
        };
        
        // Create call via Flowroute Voice API
        const response = await axios.post(
            `${FLOWROUTE_VOICE_API}/calls`,
            callData,
            {
                headers: {
                    'Authorization': `Basic ${flowrouteAuth}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        // Log the call
        const callRecord = {
            callId: response.data.data.id || `call_${Date.now()}`,
            type: 'outgoing',
            from: fromNumber,
            to: toNumber,
            extension: extension,
            timestamp: new Date().toISOString(),
            status: 'initiated',
            duration: 0,
            bridgeCall: !!staffPhone,
            staffPhone: staffPhone
        };
        
        const callLog = loadCallLog();
        callLog.push(callRecord);
        saveCallLog(callLog);
        
        return {
            success: true,
            callId: response.data.data?.id || callRecord.callId,
            message: staffPhone 
                ? 'Calling your phone now. When you answer, we\'ll connect you to the destination.'
                : 'Call initiated successfully'
        };
        
    } catch (error) {
        console.error('Error making outbound call:', error.response?.data || error.message);
        
        // If voice API isn't available, provide helpful message
        if (error.response?.status === 404) {
            return {
                success: false,
                error: 'Voice calling requires additional setup. Would you like to use click-to-call bridge (calls your phone first)?'
            };
        }
        
        return {
            success: false,
            error: error.response?.data?.errors || error.message
        };
    }
}

/**
 * Send SMS via Flowroute
 * @param {string} to - Destination phone number
 * @param {string} from - Your Flowroute DID
 * @param {string} message - SMS content
 */
async function sendSMS(to, from, message) {
    try {
        const toNumber = formatE164(to);
        const fromNumber = formatE164(from);
        
        console.log(`Sending SMS from ${fromNumber} to ${toNumber}`);
        
        const response = await axios.post(
            `${FLOWROUTE_API_BASE}/messages`,
            {
                to: toNumber,
                from: fromNumber,
                body: message
            },
            {
                headers: {
                    'Authorization': `Basic ${flowrouteAuth}`,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        // Log SMS
        const smsRecord = {
            messageId: response.data.data.id,
            type: 'sms_sent',
            from: fromNumber,
            to: toNumber,
            body: message,
            timestamp: new Date().toISOString(),
            status: 'sent'
        };
        
        const callLog = loadCallLog();
        callLog.push(smsRecord);
        saveCallLog(callLog);
        
        return {
            success: true,
            messageId: response.data.data.id
        };
        
    } catch (error) {
        console.error('Error sending SMS:', error.response?.data || error.message);
        return {
            success: false,
            error: error.response?.data?.errors || error.message
        };
    }
}

// ==========================================
// INBOUND CALL HANDLING (Webhook)
// ==========================================

/**
 * Handle incoming call webhook from Flowroute
 * Returns TwiML-like instructions for call routing
 */
function handleIncomingCall(req, res) {
    const { From, To, CallSid } = req.body;
    
    console.log(`Incoming call from ${From} to ${To}`);
    
    // Log the call
    const callRecord = {
        callId: CallSid,
        type: 'incoming',
        from: From,
        to: To,
        timestamp: new Date().toISOString(),
        status: 'ringing',
        duration: 0
    };
    
    const callLog = loadCallLog();
    callLog.push(callRecord);
    saveCallLog(callLog);
    
    // Check business hours
    const now = new Date();
    const hour = now.getHours();
    const isBusinessHours = hour >= 9 && hour < 17; // 9 AM - 5 PM
    
    // Build call routing response
    let response = {
        call_id: CallSid,
        action: 'route'
    };
    
    if (isBusinessHours) {
        // Route to extensions during business hours
        response.route_to = process.env.PBX_MAIN_EXTENSION || '101';
        response.timeout = 30;
        response.voicemail_on_timeout = true;
    } else {
        // After hours - play message and offer voicemail
        response.action = 'voicemail';
        response.greeting = 'after_hours';
    }
    
    res.json(response);
}

/**
 * Handle incoming SMS webhook
 */
function handleIncomingSMS(req, res) {
    const { From, To, Body, MessageSid } = req.body;
    
    console.log(`Incoming SMS from ${From}: ${Body}`);
    
    // Log SMS
    const smsRecord = {
        messageId: MessageSid,
        type: 'sms_received',
        from: From,
        to: To,
        body: Body,
        timestamp: new Date().toISOString(),
        status: 'received',
        read: false
    };
    
    const callLog = loadCallLog();
    callLog.push(smsRecord);
    saveCallLog(callLog);
    
    // Auto-respond (optional)
    // const autoReply = "Thank you for contacting Horizon House. A staff member will respond shortly.";
    // sendSMS(From, To, autoReply);
    
    res.json({ success: true });
}

/**
 * Handle call status updates (answered, completed, etc.)
 */
function handleCallStatus(req, res) {
    const { CallSid, CallStatus, CallDuration } = req.body;
    
    console.log(`Call ${CallSid} status: ${CallStatus}, duration: ${CallDuration}s`);
    
    // Update call log
    const callLog = loadCallLog();
    const callIndex = callLog.findIndex(c => c.callId === CallSid);
    
    if (callIndex !== -1) {
        callLog[callIndex].status = CallStatus.toLowerCase();
        callLog[callIndex].duration = parseInt(CallDuration) || 0;
        callLog[callIndex].endTime = new Date().toISOString();
        saveCallLog(callLog);
    }
    
    res.json({ success: true });
}

/**
 * Handle voicemail recording webhook
 */
function handleVoicemail(req, res) {
    const { CallSid, From, To, RecordingUrl, RecordingDuration } = req.body;
    
    console.log(`New voicemail from ${From}, duration: ${RecordingDuration}s`);
    
    const voicemail = {
        id: `VM-${Date.now()}`,
        callId: CallSid,
        from: From,
        to: To,
        recordingUrl: RecordingUrl,
        duration: parseInt(RecordingDuration) || 0,
        timestamp: new Date().toISOString(),
        listened: false,
        transcription: null
    };
    
    const voicemails = loadVoicemails();
    voicemails.push(voicemail);
    saveVoicemail(voicemails);
    
    res.json({ success: true });
}

// ==========================================
// CALL LOG & MANAGEMENT
// ==========================================

/**
 * Get call log with filters
 */
function getCallLog(filters = {}) {
    let callLog = loadCallLog();
    
    // Apply filters
    if (filters.type) {
        callLog = callLog.filter(c => c.type === filters.type);
    }
    
    if (filters.date) {
        const startOfDay = new Date(filters.date);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(filters.date);
        endOfDay.setHours(23, 59, 59, 999);
        
        callLog = callLog.filter(c => {
            const callDate = new Date(c.timestamp);
            return callDate >= startOfDay && callDate <= endOfDay;
        });
    }
    
    // Sort by most recent first
    callLog.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    return callLog;
}

/**
 * Get voicemails
 */
function getVoicemails(unreadOnly = false) {
    let voicemails = loadVoicemails();
    
    if (unreadOnly) {
        voicemails = voicemails.filter(v => !v.listened);
    }
    
    voicemails.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    return voicemails;
}

/**
 * Mark voicemail as listened
 */
function markVoicemailListened(voicemailId) {
    const voicemails = loadVoicemails();
    const vm = voicemails.find(v => v.id === voicemailId);
    
    if (vm) {
        vm.listened = true;
        saveVoicemail(voicemails);
        return true;
    }
    
    return false;
}

/**
 * Delete voicemail
 */
function deleteVoicemail(voicemailId) {
    let voicemails = loadVoicemails();
    voicemails = voicemails.filter(v => v.id !== voicemailId);
    saveVoicemail(voicemails);
    return true;
}

// ==========================================
// UTILITY FUNCTIONS
// ==========================================

/**
 * Format phone number to E.164 format
 * @param {string} number - Phone number in any format
 * @returns {string} E.164 formatted number (+1XXXXXXXXXX)
 */
function formatE164(number) {
    // Remove all non-digits
    let digits = number.replace(/\D/g, '');
    
    // Add country code if not present
    if (digits.length === 10) {
        digits = '1' + digits; // USA/Canada
    }
    
    // Add + prefix
    return '+' + digits;
}

/**
 * Get call statistics
 */
function getCallStats(date = null) {
    const callLog = getCallLog({ date });
    
    const stats = {
        totalCalls: 0,
        incomingCalls: 0,
        outgoingCalls: 0,
        missedCalls: 0,
        totalMinutes: 0,
        avgDuration: 0,
        smsCount: 0
    };
    
    callLog.forEach(entry => {
        if (entry.type === 'incoming') {
            stats.incomingCalls++;
            if (entry.status === 'missed' || entry.status === 'no-answer') {
                stats.missedCalls++;
            }
        } else if (entry.type === 'outgoing') {
            stats.outgoingCalls++;
        } else if (entry.type === 'sms_sent' || entry.type === 'sms_received') {
            stats.smsCount++;
        }
        
        if (entry.duration) {
            stats.totalMinutes += Math.ceil(entry.duration / 60);
        }
    });
    
    stats.totalCalls = stats.incomingCalls + stats.outgoingCalls;
    
    if (stats.totalCalls > 0) {
        const totalDuration = callLog
            .filter(c => c.duration)
            .reduce((sum, c) => sum + c.duration, 0);
        stats.avgDuration = Math.round(totalDuration / stats.totalCalls);
    }
    
    return stats;
}

/**
 * Get DIDs from Flowroute account
 */
async function getFlowrouteDIDs() {
    try {
        const response = await axios.get(
            `${FLOWROUTE_API_BASE}/numbers`,
            {
                headers: {
                    'Authorization': `Basic ${flowrouteAuth}`
                }
            }
        );
        
        return response.data.data || [];
    } catch (error) {
        console.error('Error fetching DIDs:', error.response?.data || error.message);
        return [];
    }
}

module.exports = {
    makeOutboundCall,
    sendSMS,
    handleIncomingCall,
    handleIncomingSMS,
    handleCallStatus,
    handleVoicemail,
    getCallLog,
    getVoicemails,
    markVoicemailListened,
    deleteVoicemail,
    getCallStats,
    getFlowrouteDIDs,
    formatE164
};
