import re

path = r'incident-report.html'
with open(path, 'r', encoding='utf-8') as f:
    html = f.read()

# ── 1. REORDER SECTIONS ───────────────────────────────────────
# Current order: StaffPanel, Sec1, Sec2, Sec3, Sec4...
# New order:     Sec2, Sec3, StaffPanel, Sec1, Sec4...

# Find the block we need to rearrange (StaffPanel start → just before Sec4 comment)
reorder_start = html.index('<section data-id="18"')
reorder_end   = html.index('\n<!-- SECTION 4:')

block = html[reorder_start:reorder_end]

def extract_section(text, start_marker, end_marker):
    s = text.find(start_marker)
    if s == -1: raise ValueError(f'Marker not found: {start_marker!r}')
    e = text.find(end_marker, s)
    if e == -1: e = len(text)
    return text[s:e]

staff_html = extract_section(block, '<section data-id="18"', '\n\n<!-- SECTION 1:')
sec1_html  = extract_section(block, '<!-- SECTION 1:', '\n\n<!-- SECTION 2:')
sec2_html  = extract_section(block, '<!-- SECTION 2:', '\n\n<!-- SECTION 3:')
sec3_html  = extract_section(block, '<!-- SECTION 3:', '\n\n')

# Update section badge numbers
sec2_html = sec2_html.replace(
    '>2</span>\n    <span data-id="137">Member(s) Involved<',
    '>1</span>\n    <span data-id="137">Member(s) Involved<'
)
sec3_html = sec3_html.replace(
    '>3</span>\n    <span data-id="148">Witnesses',
    '>2</span>\n    <span data-id="148">Witnesses'
)
sec1_html = sec1_html.replace(
    '>1</span>\n    <span data-id="47">Incident Information<',
    '>4</span>\n    <span data-id="47">Incident Information<'
)

# Rename Staff Panel header
staff_html = staff_html.replace('Reporting Staff \u2013 Auto-Fill', 'Reported By')
staff_html = staff_html.replace('Reporting Staff &#8211; Auto-Fill', 'Reported By')
staff_html = staff_html.replace('Reporting Staff – Auto-Fill', 'Reported By')

new_block = (sec2_html.rstrip() + '\n\n' +
             sec3_html.rstrip() + '\n\n' +
             staff_html.rstrip() + '\n\n' +
             sec1_html.rstrip())

html = html[:reorder_start] + new_block + html[reorder_end:]

# ── 2. RENAME SECTION 4 HEADER ────────────────────────────────
html = html.replace(
    '<span data-id="166">Incident Narrative</span>',
    '<span data-id="166">Incident Description</span>'
)
# Update its badge to 5
html = html.replace(
    '<span data-id="165" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">4</span>\n    <span data-id="166">Incident Description',
    '<span data-id="165" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">5</span>\n    <span data-id="166">Incident Description'
)

# ── 3. RENAME SECTION 5 HEADER ────────────────────────────────
html = html.replace(
    '<span data-id="179">Immediate Actions Taken</span>',
    '<span data-id="179">Action Taken</span>'
)
html = html.replace(
    '<span data-id="178" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">5</span>\n    <span data-id="179">Action Taken',
    '<span data-id="178" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">6</span>\n    <span data-id="179">Action Taken'
)

# ── 4. REMOVE DUPLICATE SUPERVISOR NOTIFIED RADIO ─────────────
# Remove the entire grid row containing both radio groups, replace with just family notified
old_radio_grid = '''    <div data-id="206" class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div>
        <label data-id="207" class="block mb-1">On-call supervisor notified?</label>
        <div data-id="208" class="radio-group">
          <label data-id="209"><input data-id="210" type="radio" name="supervisor-notified" value="Yes" class="supervisor-notified-radio" /> Yes</label>
          <label data-id="211"><input data-id="212" type="radio" name="supervisor-notified" value="No" class="supervisor-notified-radio" /> No</label>
        </div>
      </div>
      <div>
        <label data-id="222" class="block mb-1">Family/emergency contact notified?</label>
        <div data-id="223" class="radio-group">
          <label data-id="224"><input data-id="225" type="radio" name="family-notified" value="Yes" class="family-notified-radio" /> Yes</label>
          <label data-id="226"><input data-id="227" type="radio" name="family-notified" value="No" class="family-notified-radio" /> No</label>
        </div>
      </div>
    </div>'''

new_radio_grid = '''    <div>
      <label data-id="222" class="block mb-1">Family/emergency contact notified?</label>
      <div data-id="223" class="radio-group">
        <label data-id="224"><input data-id="225" type="radio" name="family-notified" value="Yes" class="family-notified-radio" /> Yes</label>
        <label data-id="226"><input data-id="227" type="radio" name="family-notified" value="No" class="family-notified-radio" /> No</label>
      </div>
    </div>'''

if old_radio_grid in html:
    html = html.replace(old_radio_grid, new_radio_grid)
    print('Removed duplicate supervisor radio.')
else:
    print('WARNING: Could not find supervisor radio grid - may need manual fix.')

# Also make supervisor-notified-details show when checkbox is checked (not radio)
# Change the conditional-field class to always show when checkbox #actions-taken-c1d2 has the value
# We'll show it by making it non-conditional and instead toggled by checkbox
# Change the div from conditional-field to normal, and we'll update JS separately
html = html.replace(
    '    <!-- Conditional Details for Supervisor Notified -->\n    <div data-id="213" class="conditional-field" id="supervisor-notified-details-k9l0">',
    '    <!-- Supervisor Details (shown when On-Call Supervisor Notified checkbox is checked) -->\n    <div data-id="213" class="conditional-field" id="supervisor-notified-details-k9l0" style="display:none;">'
)

# ── 5. RENAME SECTION 6 → OUTCOME ─────────────────────────────
html = html.replace(
    '<!-- SECTION 6: FOLLOW-UP ACTIONS -->',
    '<!-- SECTION 7: OUTCOME -->'
)
html = html.replace(
    '<span data-id="245">Follow-Up Actions</span>',
    '<span data-id="245">Outcome</span>'
)
html = html.replace(
    '<span data-id="244" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">6</span>\n    <span data-id="245">Outcome',
    '<span data-id="244" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">7</span>\n    <span data-id="245">Outcome'
)

# ── 6. ADD DISCIPLINARY ACTION to Outcome section ─────────────
disciplinary_html = '''    <div>
      <label style="font-weight:600;">Disciplinary Action</label>
      <div class="radio-group mt-1 mb-2">
        <label><input type="radio" name="disciplinary-action" value="Yes" id="disciplinary-yes" /> Yes</label>
        <label><input type="radio" name="disciplinary-action" value="No" id="disciplinary-no" /> No</label>
        <label><input type="radio" name="disciplinary-action" value="Pending" id="disciplinary-pending" /> Pending</label>
      </div>
      <label for="disciplinary-description">Disciplinary Action Description</label>
      <textarea id="disciplinary-description" rows="3" placeholder="Describe the disciplinary action taken or planned (e.g. verbal warning, written warning, probation, discharge)&#8230;"></textarea>
    </div>'''

# Insert before the closing </div></section> of section 6
old_sec6_close = '''    <div data-id="277">
      <label data-id="278" for="followup-notes-q1r2">Notes</label>
      <textarea data-id="279" id="followup-notes-q1r2" rows="3" placeholder="Optional notes\u2026"></textarea>
    </div>
  </div>
</section>

<!-- SECTION 7:'''

new_sec6_close = '''    <div data-id="277">
      <label data-id="278" for="followup-notes-q1r2">Notes</label>
      <textarea data-id="279" id="followup-notes-q1r2" rows="3" placeholder="Optional notes\u2026"></textarea>
    </div>
''' + disciplinary_html + '''
  </div>
</section>

<!-- SECTION 8:'''

if old_sec6_close in html:
    html = html.replace(old_sec6_close, new_sec6_close)
    print('Added disciplinary action field.')
else:
    # Try without ellipsis encoding issues
    idx = html.find('id="followup-notes-q1r2" rows="3"')
    if idx != -1:
        close_idx = html.find('</section>', idx) + len('</section>')
        section7_idx = html.find('\n<!-- SECTION 7:', idx)
        if section7_idx == -1:
            section7_idx = html.find('\n<!-- SECTION 8:', idx)
        insert_point = html.rfind('  </div>\n</section>', idx, close_idx)
        if insert_point != -1:
            html = html[:insert_point] + '\n' + disciplinary_html + '\n' + html[insert_point:]
            print('Added disciplinary action field (fallback method).')
        else:
            print('WARNING: Could not add disciplinary action field.')
    else:
        print('WARNING: followup-notes not found.')

# ── 7. SECTION 7 SUPERVISOR REVIEW badge update ───────────────
html = html.replace(
    '<span data-id="282" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">7</span>\n    <span data-id="283">Supervisor Review',
    '<span data-id="282" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">8</span>\n    <span data-id="283">Supervisor Review'
)

# ── 8. SECTION 8 ATTACHMENTS badge update ────────────────────
html = html.replace(
    '<span data-id="324" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">8</span>\n    <span data-id="325">Attachments',
    '<span data-id="324" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">9</span>\n    <span data-id="325">Attachments'
)

# ── 9. SIGNATURES: Admin only (remove staff signature) ────────
old_sig_section = '''  <div data-id="344" class="p-4 md:p-6 space-y-6">
    <!-- Staff Signature -->
    <div data-id="345">
      <h3 data-id="346" class="font-semibold text-navy-900 mb-3">Reporting Staff Signature</h3>
      <div data-id="347" class="border border-clinical-border rounded-lg p-4 bg-clinical-bg">
        <canvas data-id="348" id="staff-sig-canvas-y5z6" class="signature-canvas w-full" width="700" height="150"></canvas>
        <div data-id="349" class="flex items-center gap-3 mt-2">
          <button data-id="350" class="btn btn-secondary text-xs" id="clear-staff-sig-a7b8"><i data-id="351" data-lucide="eraser" class="w-3 h-3"></i> Clear</button>
        </div>
        <div data-id="352" class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
          <div data-id="353"><label data-id="354" for="staff-sig-name-c9d0">Printed Name</label><input data-id="355" type="text" id="staff-sig-name-c9d0" readonly class="bg-gray-50" /></div>
          <div data-id="356"><label data-id="357" for="staff-sig-role-e1f2">Title / Role</label><input data-id="358" type="text" id="staff-sig-role-e1f2" readonly class="bg-gray-50" /></div>
          <div data-id="359"><label data-id="360" for="staff-sig-time-g3h4">Submission Timestamp</label><input data-id="361" type="text" id="staff-sig-time-g3h4" readonly class="bg-gray-50 tabular-nums" /></div>
        </div>
      </div>
    </div>
    <!-- Supervisor Signature -->
    <div data-id="362">
      <h3 data-id="363" class="font-semibold text-navy-900 mb-3">Supervisor Signature</h3>'''

new_sig_section = '''  <div data-id="344" class="p-4 md:p-6 space-y-6">
    <!-- Admin Signature -->
    <div data-id="362">
      <h3 data-id="363" class="font-semibold text-navy-900 mb-3">Administrator Signature</h3>'''

if old_sig_section in html:
    html = html.replace(old_sig_section, new_sig_section)
    print('Removed staff signature, renamed to Administrator Signature.')
else:
    print('WARNING: Could not find staff signature block - may need manual fix.')

# ── 10. UPDATE SECTION 9 BADGE ───────────────────────────────
html = html.replace(
    '<span data-id="340" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">9</span>\n    <span data-id="341">Signatures',
    '<span data-id="340" class="bg-navy-900 text-white text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center">10</span>\n    <span data-id="341">Signatures'
)

# ── 11. FIX JS: remove staffSigPad, update supervisor radio JS ─
# Remove staffSigPad initialization
html = html.replace(
    'const staffSigPad = initSignaturePad(\'staff-sig-canvas-y5z6\');\n',
    ''
)
html = html.replace(
    "const staffSigPad = initSignaturePad('staff-sig-canvas-y5z6');\n",
    ''
)
# Remove clear-staff-sig listener
html = html.replace(
    "$('clear-staff-sig-a7b8').addEventListener('click', () => staffSigPad.clear());\n",
    ''
)
# Remove staffSigPad.clear() from form clear
html = html.replace(
    'staffSigPad.clear(); superSigPad.clear();',
    'superSigPad.clear();'
)
# Remove staffSigPad from PDF export
html = re.sub(r'\s*if \(staffSigPad\.hasSignature\(\)\) \{[^}]+\}\s*', '\n    ', html)
# Remove supervisor-notified-radio JS setup
html = html.replace(
    "setupRadioConditional('supervisor-notified-radio', 'supervisor-notified-details-k9l0');\n",
    ''
)
html = html.replace(
    "setupRadioConditional('supervisor-notified-radio', 'supervisor-no",
    "// removed supervisor-notified-radio setup\n// setupRadioConditional('supervisor-notified-radio', 'supervisor-no"
)

# Add JS to toggle supervisor details from checkbox
supervisor_checkbox_js = """
// Show supervisor details when On-Call Supervisor Notified checkbox is checked
(function() {
  var cbs = document.querySelectorAll('.action-cb');
  function updateSupDetails() {
    var checked = Array.from(cbs).some(function(cb) {
      return cb.value === 'On-Call Supervisor Notified' && cb.checked;
    });
    var det = document.getElementById('supervisor-notified-details-k9l0');
    if (det) det.style.display = checked ? '' : 'none';
  }
  cbs.forEach(function(cb) { cb.addEventListener('change', updateSupDetails); });
  updateSupDetails();
})();
"""

# Insert before the last </script> tag
last_script_close = html.rfind('</script>')
if last_script_close != -1:
    html = html[:last_script_close] + supervisor_checkbox_js + html[last_script_close:]
    print('Added supervisor checkbox JS.')

with open(path, 'w', encoding='utf-8') as f:
    f.write(html)

print('Done. incident-report.html updated.')
