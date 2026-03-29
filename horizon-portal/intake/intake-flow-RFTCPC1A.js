// Intake Flow Manager
// Handles sequential form navigation and data auto-population

const INTAKE_FORMS = [
    { id: 1, name: 'member-agreement.html', title: 'Member Agreement' },
    { id: 2, name: 'licensee-agreement.html', title: 'Licensee Agreement' },
    { id: 3, name: 'release-of-information.html', title: 'Release of Information' },
    { id: 4, name: 'emergency-contact.html', title: 'Emergency Contact' },
    { id: 5, name: 'release-of-liability.html', title: 'Facilities Liability Release' },
    { id: 6, name: 'personal-property-release.html', title: 'Personal Property Release' }
];

// Get intake data from sessionStorage
function getIntakeData() {
    const data = sessionStorage.getItem('intakeData');
    return data ? JSON.parse(data) : null;
}

// Get intake progress
function getIntakeProgress() {
    const progress = sessionStorage.getItem('intakeProgress');
    return progress ? JSON.parse(progress) : { currentForm: 1, completedForms: [] };
}

// Update intake progress
function updateIntakeProgress(formId) {
    const progress = getIntakeProgress();
    if (!progress.completedForms.includes(formId)) {
        progress.completedForms.push(formId);
    }
    progress.currentForm = formId + 1;
    sessionStorage.setItem('intakeProgress', JSON.stringify(progress));
}

// Check if we're in intake mode
function isIntakeMode() {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('intake') === 'true' && getIntakeData() !== null;
}

// Navigate to next form
function goToNextForm(currentFormId) {
    updateIntakeProgress(currentFormId);
    
    if (currentFormId >= INTAKE_FORMS.length) {
        // All forms complete - go to completion page
        window.location.href = 'intake-complete.html';
    } else {
        // Go to next form immediately for iPad guided access mode
        const nextForm = INTAKE_FORMS[currentFormId];
        window.location.replace(`${nextForm.name}?intake=true`);
    }
}

// Auto-populate common fields
function autoPopulateFields() {
    if (!isIntakeMode()) return;
    
    const data = getIntakeData();
    if (!data) return;
    
    // Map of common field IDs to data keys
    const fieldMappings = {
        'firstName': data.firstName,
        'lastName': data.lastName,
        'memberFirstName': data.firstName,
        'memberLastName': data.lastName,
        'dateOfBirth': data.dateOfBirth,
        'dob': data.dateOfBirth,
        'phone': data.phone,
        'memberPhone': data.phone,
        'admissionDate': data.admissionDate,
        'roomAssignment': data.roomAssignment,
        'room': data.roomAssignment,
        'monthlyFee': data.monthlyFee
    };
    
    // Auto-fill fields
    for (const [fieldId, value] of Object.entries(fieldMappings)) {
        const field = document.getElementById(fieldId);
        if (field && value) {
            field.value = value;
        }
    }
    
    // Set today's date for signature dates
    const today = new Date().toISOString().split('T')[0];
    const signatureDateField = document.getElementById('signatureDate');
    if (signatureDateField && !signatureDateField.value) {
        signatureDateField.value = today;
    }
}

// Show intake progress bar
function showIntakeProgress(currentFormId) {
    if (!isIntakeMode()) return;
    
    const progress = getIntakeProgress();
    
    // Create progress bar if it doesn't exist
    if (!document.getElementById('intakeProgressBar')) {
        const progressHTML = `
            <div id="intakeProgressBar" style="position: fixed; top: 0; left: 0; right: 0; background: #1a202c; color: white; padding: 15px 20px; z-index: 10000; box-shadow: 0 2px 10px rgba(0,0,0,0.2);">
                <div style="max-width: 1200px; margin: 0 auto; display: flex; align-items: center; justify-content: space-between;">
                    <div>
                        <div style="font-size: 14px; opacity: 0.8; margin-bottom: 5px;">Member ID: <strong>${getIntakeData().memberId}</strong> - ${getIntakeData().firstName} ${getIntakeData().lastName}</div>
                        <div style="font-size: 16px; font-weight: 600;">Form ${currentFormId} of ${INTAKE_FORMS.length}: ${INTAKE_FORMS[currentFormId - 1].title}</div>
                    </div>
                    <div style="font-size: 24px; font-weight: 700;">${Math.round((currentFormId / INTAKE_FORMS.length) * 100)}%</div>
                </div>
                <div style="background: rgba(255,255,255,0.2); height: 6px; border-radius: 3px; margin-top: 10px; overflow: hidden;">
                    <div style="background: #48bb78; height: 100%; width: ${(currentFormId / INTAKE_FORMS.length) * 100}%; transition: width 0.3s;"></div>
                </div>
            </div>
        `;
        document.body.insertAdjacentHTML('afterbegin', progressHTML);
        
        // Add padding to body so content isn't hidden under progress bar
        document.body.style.paddingTop = '110px';
    }
}

// Initialize intake mode for a form
function initializeIntakeMode(currentFormId) {
    if (!isIntakeMode()) return false;
    
    showIntakeProgress(currentFormId);
    autoPopulateFields();
    
    return true;
}

// Clear intake data (call on completion or cancellation)
function clearIntakeData() {
    sessionStorage.removeItem('intakeData');
    sessionStorage.removeItem('intakeProgress');
}
