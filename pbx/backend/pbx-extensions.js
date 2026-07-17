// ==========================================
// EXTENSION ROUTING & MANAGEMENT
// ==========================================

// Extension Directory
const EXTENSIONS = {
    '101': {
        name: 'Admin Office',
        forwardTo: '+16265551001',  // Replace with actual admin cell/desk phone
        voicemail: true,
        email: 'admin@horizonhouse.com',
        hours: {
            enabled: true,
            start: 9,  // 9 AM
            end: 17    // 5 PM
        }
    },
    '102': {
        name: 'Intake Coordinator',
        forwardTo: '+16265551002',  // Replace with actual intake coordinator phone
        voicemail: true,
        email: 'intake@horizonhouse.com',
        hours: {
            enabled: true,
            start: 8,
            end: 18
        }
    },
    '103': {
        name: 'House Manager',
        forwardTo: '+16265551003',  // Replace with house manager phone
        voicemail: true,
        email: 'manager@horizonhouse.com',
        hours: {
            enabled: false  // Available 24/7
        }
    },
    '104': {
        name: 'Accounting',
        forwardTo: '+16265551004',
        voicemail: true,
        email: 'accounting@horizonhouse.com',
        hours: {
            enabled: true,
            start: 9,
            end: 17
        }
    },
    '0': {
        name: 'Operator',
        forwardTo: '+16265551001',  // Default to admin
        voicemail: false,
        ringGroup: ['101', '102', '103']  // Ring multiple extensions
    }
};

/**
 * Route incoming call to extension
 */
function routeToExtension(extensionNumber, callerNumber) {
    const extension = EXTENSIONS[extensionNumber];
    
    if (!extension) {
        return {
            success: false,
            message: 'Extension not found'
        };
    }
    
    // Check business hours if enabled
    if (extension.hours?.enabled) {
        const now = new Date();
        const hour = now.getHours();
        
        if (hour < extension.hours.start || hour >= extension.hours.end) {
            return {
                success: false,
                action: 'voicemail',
                message: `${extension.name} is currently unavailable. Please leave a message.`,
                voicemailEmail: extension.email
            };
        }
    }
    
    // Handle ring groups (multiple extensions)
    if (extension.ringGroup) {
        return {
            success: true,
            action: 'ring-group',
            extensions: extension.ringGroup.map(ext => EXTENSIONS[ext]),
            timeout: 30  // seconds before going to voicemail
        };
    }
    
    // Forward to destination
    return {
        success: true,
        action: 'forward',
        destination: extension.forwardTo,
        name: extension.name,
        timeout: 20,  // seconds before voicemail
        voicemail: extension.voicemail
    };
}

/**
 * Handle IVR (Interactive Voice Response) menu
 */
function handleIVROption(digit, callerNumber) {
    const routing = {
        '1': '102',  // Press 1 for Intake/Admissions
        '2': '103',  // Press 2 for House Manager
        '3': '104',  // Press 3 for Accounting/Billing
        '0': '0',    // Press 0 for Operator
        '*': '101',  // * for Admin
        '#': 'directory'  // # for directory
    };
    
    const extensionNumber = routing[digit];
    
    if (!extensionNumber) {
        return {
            success: false,
            message: 'Invalid selection. Please try again.'
        };
    }
    
    if (extensionNumber === 'directory') {
        return {
            success: true,
            action: 'directory',
            message: 'Extension directory...'
        };
    }
    
    return routeToExtension(extensionNumber, callerNumber);
}

/**
 * Main incoming call handler with IVR
 */
function handleIncomingCall(callerNumber, dialedNumber) {
    // Default routing for main number
    return {
        success: true,
        action: 'ivr',
        greeting: 'Thank you for calling Horizon House. Press 1 for admissions, Press 2 for current residents, Press 3 for accounting, or press 0 for the operator.',
        timeout: 10,  // seconds to wait for input
        defaultExtension: '0'  // Go to operator if no input
    };
}

/**
 * Get extension status
 */
function getExtensionStatus(extensionNumber) {
    const extension = EXTENSIONS[extensionNumber];
    
    if (!extension) {
        return { available: false, reason: 'not_found' };
    }
    
    // Check business hours
    if (extension.hours?.enabled) {
        const now = new Date();
        const hour = now.getHours();
        
        if (hour < extension.hours.start || hour >= extension.hours.end) {
            return {
                available: false,
                reason: 'outside_hours',
                nextAvailable: `${extension.hours.start}:00 AM`
            };
        }
    }
    
    return {
        available: true,
        name: extension.name,
        extension: extensionNumber
    };
}

/**
 * List all extensions
 */
function listExtensions() {
    return Object.entries(EXTENSIONS).map(([number, details]) => ({
        extension: number,
        name: details.name,
        hasVoicemail: details.voicemail,
        isRingGroup: !!details.ringGroup,
        hours: details.hours
    }));
}

module.exports = {
    EXTENSIONS,
    routeToExtension,
    handleIVROption,
    handleIncomingCall,
    getExtensionStatus,
    listExtensions
};
