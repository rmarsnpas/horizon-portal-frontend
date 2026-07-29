#!/usr/bin/env python3
"""Add totals summary and available beds to census printout."""
import sys

path = "staff-dashboard.html"
with open(path, encoding="utf-8") as f:
    c = f.read()

EN = "\u2013"  # en-dash (used in existing template)

# ── Section to replace: from "const printDate" through end of html template
OLD = (
    "                        const printDate = today.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });\n"
    "                        const hwNote = inclHW && hwCount > 0 ? ` &nbsp;&bull;&nbsp; ${hwCount} Hold/Wait` : '';\n"
    "                        const html = `<!DOCTYPE html><html><head><title>Census Report \u2013 ${printDate}</title>\n"
    "<style>\n"
    "  *{box-sizing:border-box}\n"
    "  body{font-family:Arial,sans-serif;font-size:10.5px;margin:0;color:#1a1a2e}\n"
    "  .rh{background:#1a3a5c;color:white;padding:13px 18px 11px;display:flex;justify-content:space-between;align-items:flex-end}\n"
    "  .rh-org{font-size:19px;font-weight:800;letter-spacing:.4px}\n"
    "  .rh-sub{font-size:10px;opacity:.82;font-style:italic;margin-top:2px}\n"
    "  .rh-date{text-align:right;font-size:10px;opacity:.9;line-height:1.6}\n"
    "  .rm{background:#d6e4f7;border-bottom:2px solid #1a3a5c;padding:5px 18px;font-size:10px;color:#1a3a5c;font-weight:700;display:flex;gap:22px}\n"
    "  .rb{padding:10px 18px}\n"
    "  table{border-collapse:collapse;width:100%}\n"
    "  th{background:#1a3a5c;color:white;padding:6px 8px;text-align:left;white-space:nowrap;font-size:9.5px;font-weight:700;letter-spacing:.3px;border-right:1px solid rgba(255,255,255,.15)}\n"
    "  th:last-child{border-right:none}\n"
    "  td{border-bottom:1px solid #dde4f0;padding:3.5px 8px;white-space:nowrap;vertical-align:middle}\n"
    "  tr:nth-child(even) td{background:#eef2fb}\n"
    "  tr:nth-child(odd) td{background:#ffffff}\n"
    "  tr.hw-row td{background:#fff3cd!important}\n"
    "  tr.hw-row td:first-child{border-left:3px solid #f59e0b}\n"
    "  .hw-badge{display:inline-block;background:#f59e0b;color:white;border-radius:3px;font-size:7.5px;padding:1px 4px;margin-left:3px;font-weight:700;vertical-align:middle;line-height:1.5}\n"
    "  @media print{@page{margin:10mm;size:landscape}body{-webkit-print-color-adjust:exact;print-color-adjust:exact}}\n"
    "</style></head><body>\n"
    '<div class="rh">\n'
    '  <div><div class="rh-org">Horizon House</div><div class="rh-sub">${filterLabels[filterVal]}${inclHW && hwCount > 0 ? \' + Hold/Wait\' : \'\'}</div></div>\n'
    '  <div class="rh-date">Census Report<br>${printDate}</div>\n'
    "</div>\n"
    '<div class="rm"><span>${members.length} record${members.length !== 1 ? \'s\' : \'\'}${hwNote}</span></div>\n'
    '<div class="rb"><table><thead>${headerRow}</thead><tbody>${rows}</tbody></table></div>\n'
    "</body></html>`;"
)

NEW = (
    "                        const printDate = today.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' });\n"
    "\n"
    "                        // ── Totals ─────────────────────────────────────────\n"
    "                        const activeM = members.filter(m => {\n"
    "                            const st = String(m.STATUS || m.status || m.STATU || '').trim().toUpperCase();\n"
    "                            return st !== 'H' && st !== 'W';\n"
    "                        });\n"
    "                        const totM    = activeM.filter(m => String(m['M/F'] || m.GENDER || m.gender || '').trim().toUpperCase() === 'M').length;\n"
    "                        const totF    = activeM.filter(m => String(m['M/F'] || m.GENDER || m.gender || '').trim().toUpperCase() === 'F').length;\n"
    "                        const totRefA = activeM.filter(m => String(m.REF || m.ref || '').trim().toUpperCase() === 'A').length;\n"
    "                        const totRefH = activeM.filter(m => String(m.REF || m.ref || '').trim().toUpperCase() === 'H').length;\n"
    "                        const totRefS = activeM.filter(m => String(m.REF || m.ref || '').trim().toUpperCase() === 'S').length;\n"
    "                        const totHold = members.filter(m => String(m.STATUS || m.status || m.STATU || '').trim().toUpperCase() === 'H').length;\n"
    "                        const totWait = members.filter(m => String(m.STATUS || m.status || m.STATU || '').trim().toUpperCase() === 'W').length;\n"
    "\n"
    "                        // ── Available beds ─────────────────────────────────\n"
    "                        const availF = (window.getAvailableBeds ? window.getAvailableBeds('F') : []).sort();\n"
    "                        const availM = (window.getAvailableBeds ? window.getAvailableBeds('M') : []).sort();\n"
    "                        const bedRowF = availF.length\n"
    "                            ? availF.map(b => `<span class='bed-chip'>${b}</span>`).join('')\n"
    "                            : '<em style=\"color:#888\">None</em>';\n"
    "                        const bedRowM = availM.length\n"
    "                            ? availM.map(b => `<span class='bed-chip'>${b}</span>`).join('')\n"
    "                            : '<em style=\"color:#888\">None</em>';\n"
    "\n"
    "                        // ── Stat pills ─────────────────────────────────────\n"
    "                        const statPill = (label, n, cls='') =>\n"
    "                            `<span class='sp ${cls}'><span class='sp-n'>${n}</span><span class='sp-l'>${label}</span></span>`;\n"
    "                        const statsHtml = [\n"
    "                            statPill('Total', activeM.length, 'sp-total'),\n"
    "                            statPill('Male', totM, 'sp-m'),\n"
    "                            statPill('Female', totF, 'sp-f'),\n"
    "                            statPill('REF&nbsp;A', totRefA, 'sp-a'),\n"
    "                            statPill('REF&nbsp;H', totRefH, 'sp-h'),\n"
    "                            statPill('REF&nbsp;S', totRefS, 'sp-s'),\n"
    "                            ...(inclHW && (totHold+totWait) > 0\n"
    "                                ? [statPill('Hold', totHold, 'sp-hw'), statPill('Wait', totWait, 'sp-hw')]\n"
    "                                : []),\n"
    "                        ].join('');\n"
    "\n"
    "                        const html = `<!DOCTYPE html><html><head><title>Census Report \u2013 ${printDate}</title>\n"
    "<style>\n"
    "  *{box-sizing:border-box}\n"
    "  body{font-family:Arial,sans-serif;font-size:10.5px;margin:0;color:#1a1a2e}\n"
    "  .rh{background:#1a3a5c;color:white;padding:14px 20px 12px;display:flex;justify-content:space-between;align-items:center}\n"
    "  .rh-left{}\n"
    "  .rh-org{font-size:22px;font-weight:900;letter-spacing:.5px}\n"
    "  .rh-sub{font-size:10px;opacity:.8;font-style:italic;margin-top:3px}\n"
    "  .rh-date{text-align:right;font-size:18px;font-weight:800;line-height:1.2;letter-spacing:-.2px}\n"
    "  .rh-dateSub{font-size:9.5px;opacity:.78;font-weight:400;margin-top:3px;text-align:right}\n"
    "  .stats-bar{background:#0f2740;padding:8px 20px;display:flex;gap:10px;flex-wrap:wrap;align-items:center}\n"
    "  .sp{display:inline-flex;flex-direction:column;align-items:center;background:rgba(255,255,255,.12);border-radius:5px;padding:3px 10px;min-width:44px}\n"
    "  .sp-n{font-size:16px;font-weight:800;color:#fff;line-height:1.1}\n"
    "  .sp-l{font-size:8px;color:rgba(255,255,255,.75);text-transform:uppercase;letter-spacing:.5px;margin-top:1px}\n"
    "  .sp-total .sp-n{color:#7dd3fc}\n"
    "  .sp-m .sp-n{color:#93c5fd}\n"
    "  .sp-f .sp-n{color:#f9a8d4}\n"
    "  .sp-a .sp-n{color:#6ee7b7}\n"
    "  .sp-h .sp-n{color:#fde68a}\n"
    "  .sp-s .sp-n{color:#c4b5fd}\n"
    "  .sp-hw .sp-n{color:#fbbf24}\n"
    "  .rm{background:#d6e4f7;border-bottom:2px solid #1a3a5c;padding:4px 20px;font-size:9.5px;color:#1a3a5c;font-weight:600}\n"
    "  .rb{padding:10px 18px}\n"
    "  table{border-collapse:collapse;width:100%}\n"
    "  th{background:#1a3a5c;color:white;padding:6px 8px;text-align:left;white-space:nowrap;font-size:9.5px;font-weight:700;letter-spacing:.3px;border-right:1px solid rgba(255,255,255,.15)}\n"
    "  th:last-child{border-right:none}\n"
    "  td{border-bottom:1px solid #dde4f0;padding:3.5px 8px;white-space:nowrap;vertical-align:middle}\n"
    "  tr:nth-child(even) td{background:#eef2fb}\n"
    "  tr:nth-child(odd) td{background:#ffffff}\n"
    "  tr.hw-row td{background:#fff3cd!important}\n"
    "  tr.hw-row td:first-child{border-left:3px solid #f59e0b}\n"
    "  .hw-badge{display:inline-block;background:#f59e0b;color:white;border-radius:3px;font-size:7.5px;padding:1px 4px;margin-left:3px;font-weight:700;vertical-align:middle;line-height:1.5}\n"
    "  .beds-section{background:#f0f4ff;border-top:2px solid #1a3a5c;padding:10px 20px 14px;margin-top:4px}\n"
    "  .beds-title{font-size:11px;font-weight:800;color:#1a3a5c;text-transform:uppercase;letter-spacing:.6px;margin-bottom:6px}\n"
    "  .beds-row{display:flex;gap:28px;margin-top:4px}\n"
    "  .beds-group{}\n"
    "  .beds-group-label{font-size:9px;font-weight:700;color:#6b7280;text-transform:uppercase;letter-spacing:.4px;margin-bottom:4px}\n"
    "  .bed-chip{display:inline-block;background:#1a3a5c;color:white;border-radius:4px;padding:2px 8px;margin:2px 3px;font-size:10px;font-weight:700}\n"
    "  @media print{@page{margin:10mm;size:landscape}body{-webkit-print-color-adjust:exact;print-color-adjust:exact}}\n"
    "</style></head><body>\n"
    '<div class="rh">\n'
    '  <div class="rh-left">\n'
    '    <div class="rh-org">Horizon House</div>\n'
    '    <div class="rh-sub">${filterLabels[filterVal]}${inclHW && (totHold+totWait) > 0 ? \' + Hold/Wait\' : \'\'}</div>\n'
    '  </div>\n'
    '  <div>\n'
    '    <div class="rh-date">${printDate}</div>\n'
    '    <div class="rh-dateSub">Census Report</div>\n'
    '  </div>\n'
    "</div>\n"
    '<div class="stats-bar">${statsHtml}</div>\n'
    '<div class="rm">${members.length} record${members.length !== 1 ? \'s\' : \'\'} printed</div>\n'
    '<div class="rb"><table><thead>${headerRow}</thead><tbody>${rows}</tbody></table></div>\n'
    '<div class="beds-section">\n'
    '  <div class="beds-title">Available Beds</div>\n'
    '  <div class="beds-row">\n'
    '    <div class="beds-group"><div class="beds-group-label">Women (${availF.length} open)</div><div>${bedRowF}</div></div>\n'
    '    <div class="beds-group"><div class="beds-group-label">Men (${availM.length} open)</div><div>${bedRowM}</div></div>\n'
    '  </div>\n'
    "</div>\n"
    "</body></html>`;"
)

if OLD in c:
    c = c.replace(OLD, NEW, 1)
    print("Replaced OK")
else:
    print("ERROR: block not found")
    idx = c.find("const printDate = today.toLocaleDateString")
    if idx != -1:
        print("Found printDate at line", c[:idx].count('\n')+1)
        print(repr(c[idx:idx+120]))
    sys.exit(1)

with open(path, "w", encoding="utf-8", newline="") as f:
    f.write(c)
print("Written.")
