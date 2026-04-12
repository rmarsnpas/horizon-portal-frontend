/*
  Generates a static manifest for member invoice PDFs.

  Expected folder structure (relative to horizon-portal/):
    invoices/
      unpaid/
      paid/

  Expected filename format (required parts):
    MID<memberId>_INV<invoiceNumber>.pdf

  Optional tokens (order-independent):
    _DUEMM-DD-YYYY
    _PAIDMM-DD-YYYY
    _AMT123.45

  Examples:
    MID1234_INV2026-03_DUE03-31-2026_AMT450.00.pdf
    MID1234_INV10023_PAID04-02-2026_AMT450.pdf

  Output:
    horizon-portal/invoices/invoices.json
*/

const fs = require('fs');
const path = require('path');

const portalRoot = path.resolve(__dirname, '..');
const invoicesRoot = path.join(portalRoot, 'invoices');
const unpaidDir = path.join(invoicesRoot, 'unpaid');
const paidDir = path.join(invoicesRoot, 'paid');
const outputPath = path.join(invoicesRoot, 'invoices.json');

function listPdfs(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  return fs
    .readdirSync(dirPath, { withFileTypes: true })
    .filter((d) => d.isFile() && d.name.toLowerCase().endsWith('.pdf'))
    .map((d) => d.name);
}

function parseInvoiceFilename(fileName) {
  // MID<digits>_INV<anything_no_ext> plus optional tokens
  const base = fileName.replace(/\.pdf$/i, '');

  const midMatch = base.match(/(?:^|_)MID(\d+)(?:_|$)/i);
  const invMatch = base.match(/(?:^|_)INV([^_]+)(?:_|$)/i);

  // Accept both MM-DD-YYYY (preferred) and legacy YYYY-MM-DD
  const dueMatch = base.match(/(?:^|_)DUE(\d{2}-\d{2}-\d{4}|\d{4}-\d{2}-\d{2})(?:_|$)/i);
  const paidMatch = base.match(/(?:^|_)PAID(\d{2}-\d{2}-\d{4}|\d{4}-\d{2}-\d{2})(?:_|$)/i);
  const amtMatch = base.match(/(?:^|_)AMT(\d+(?:\.\d{1,2})?)(?:_|$)/i);

  function normalizeToMMDDYYYY(dateStr) {
    if (!dateStr) return null;
    const iso = dateStr.match(/^\d{4}-\d{2}-\d{2}$/);
    if (iso) {
      const [yyyy, mm, dd] = dateStr.split('-');
      return `${mm}-${dd}-${yyyy}`;
    }
    const us = dateStr.match(/^\d{2}-\d{2}-\d{4}$/);
    if (us) {
      return dateStr;
    }
    return null;
  }

  return {
    memberId: midMatch ? midMatch[1] : null,
    invoiceNumber: invMatch ? invMatch[1] : null,
    dueDate: normalizeToMMDDYYYY(dueMatch ? dueMatch[1] : null),
    paidDate: normalizeToMMDDYYYY(paidMatch ? paidMatch[1] : null),
    amount: amtMatch ? amtMatch[1] : null,
  };
}

function buildRecords(dirPath, status) {
  return listPdfs(dirPath).map((fileName) => {
    const parsed = parseInvoiceFilename(fileName);
    const pdfPath = path.posix.join('invoices', status, encodeURIComponent(fileName));

    return {
      memberId: parsed.memberId,
      invoiceNumber: parsed.invoiceNumber,
      status,
      dueDate: parsed.dueDate,
      paidDate: parsed.paidDate,
      amount: parsed.amount,
      pdfPath,
      fileName,
      parseOk: Boolean(parsed.memberId && parsed.invoiceNumber),
    };
  });
}

function sortInvoices(a, b) {
  // unpaid first by dueDate (then invoiceNumber), paid by paidDate desc
  if (a.status !== b.status) return a.status === 'unpaid' ? -1 : 1;

  function toSortKey(mmddyyyy) {
    // Converts MM-DD-YYYY -> YYYYMMDD for lexical sort. Unknown/invalid => ''
    if (!mmddyyyy) return '';
    const m = String(mmddyyyy).match(/^(\d{2})-(\d{2})-(\d{4})$/);
    if (!m) return '';
    const [, mm, dd, yyyy] = m;
    return `${yyyy}${mm}${dd}`;
  }

  if (a.status === 'unpaid') {
    const da = toSortKey(a.dueDate);
    const db = toSortKey(b.dueDate);
    if (da !== db) return da.localeCompare(db);
    return String(a.invoiceNumber || '').localeCompare(String(b.invoiceNumber || ''));
  }

  const pa = toSortKey(a.paidDate);
  const pb = toSortKey(b.paidDate);
  if (pa !== pb) return pb.localeCompare(pa);
  return String(a.invoiceNumber || '').localeCompare(String(b.invoiceNumber || ''));
}

function deduplicateInvoices(all) {
  // Group by memberId + invoiceNumber
  const groups = {};
  for (const inv of all) {
    const key = `${inv.memberId}||${inv.invoiceNumber}`;
    if (!groups[key]) groups[key] = [];
    groups[key].push(inv);
  }

  const result = [];
  for (const records of Object.values(groups)) {
    if (records.length === 1) { result.push(records[0]); continue; }

    // Prefer paid-with-paidDate (the _PAID<date> version) over everything else
    const paidWithDate = records.filter(r => r.status === 'paid' && r.paidDate);
    if (paidWithDate.length > 0) { result.push(paidWithDate[0]); continue; }

    // If paid exists (no date), prefer that over unpaid
    const paid = records.filter(r => r.status === 'paid');
    if (paid.length > 0) { result.push(paid[0]); continue; }

    result.push(records[0]);
  }
  return result;
}

function main() {
  const unpaid = buildRecords(unpaidDir, 'unpaid');
  const paid = buildRecords(paidDir, 'paid');

  const invoices = deduplicateInvoices([...unpaid, ...paid]).sort(sortInvoices);

  const bad = invoices.filter((i) => !i.parseOk);
  if (bad.length) {
    console.warn(`WARNING: ${bad.length} invoice PDF(s) did not match naming rules (need MID<id> and INV<invoiceNumber>):`);
    bad.slice(0, 50).forEach((i) => console.warn(` - ${i.status}/${i.fileName}`));
    if (bad.length > 50) console.warn(` - ...and ${bad.length - 50} more`);
  }

  const payload = {
    generatedAt: new Date().toISOString(),
    invoices,
  };

  fs.mkdirSync(invoicesRoot, { recursive: true });
  fs.writeFileSync(outputPath, JSON.stringify(payload, null, 2) + '\n', 'utf8');

  console.log(`Wrote ${invoices.length} invoice record(s) to: ${outputPath}`);
}

main();
