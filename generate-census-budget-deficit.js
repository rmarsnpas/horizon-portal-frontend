const XLSX = require('xlsx');

const SOURCE_PATH = 'horizon-portal/backend/members.xlsx';
const TARGET_RATE = 1500;
const now = new Date();
const reportMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
const asOfDate = now.toISOString().slice(0, 10);
const rawMemberNames = process.env.CURRENT_MEMBER_NAMES || '';
const providedMemberNames = rawMemberNames
  .split(',')
  .map((name) => name.trim())
  .filter(Boolean);
const hasMemberFilter = providedMemberNames.length > 0;
const OUTPUT_PATH = hasMemberFilter
  ? `census-budget-deficit-monthly-status1-${reportMonth}-current-members.xlsx`
  : `census-budget-deficit-monthly-status1-${reportMonth}.xlsx`;

function normalizeName(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
}

function clientMatchesProvidedName(clientName, providedName) {
  const normalizedClient = normalizeName(clientName);
  const normalizedProvided = normalizeName(providedName);
  if (!normalizedClient || !normalizedProvided) return false;
  return (
    normalizedClient === normalizedProvided ||
    normalizedClient.startsWith(normalizedProvided) ||
    normalizedProvided.startsWith(normalizedClient)
  );
}

function getHeaderIndex(headerRow, names) {
  const candidates = Array.isArray(names) ? names : [names];
  return headerRow.findIndex((cell) => {
    const normalized = String(cell || '').trim();
    return candidates.includes(normalized);
  });
}

function toNumber(value) {
  if (typeof value === 'number') return value;
  const parsed = Number(String(value || '').replace(/[$,]/g, '').trim());
  return Number.isFinite(parsed) ? parsed : 0;
}

function detectHeaderRow(rows) {
  const maxScan = Math.min(rows.length, 10);
  for (let i = 0; i < maxScan; i += 1) {
    const row = rows[i] || [];
    const values = row.map((cell) => String(cell || '').trim().toUpperCase());
    if (values.includes('ID') && values.includes('STATUS') && values.some((v) => v.includes('FIRST'))) {
      return { headerRow: row, headerRowIndex: i };
    }
  }
  return { headerRow: rows[3] || [], headerRowIndex: 3 };
}

function buildRows() {
  const workbook = XLSX.readFile(SOURCE_PATH);
  const sheet = workbook.Sheets[workbook.SheetNames[0]];
  const rows = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });

  const { headerRow, headerRowIndex } = detectHeaderRow(rows);
  const idx = {
    id: getHeaderIndex(headerRow, 'ID'),
    status: getHeaderIndex(headerRow, 'STATUS'),
    firstName: getHeaderIndex(headerRow, ['FIRST\r\nNAME', 'FIRST\nNAME', 'FIRST NAME']),
    lastName: getHeaderIndex(headerRow, ['LAST\r\nNAME', 'LAST\nNAME', 'LAST NAME']),
    rate: getHeaderIndex(headerRow, 'RATE'),
    bed: getHeaderIndex(headerRow, 'BED'),
  };

  let clients = rows
    .slice(headerRowIndex + 1)
    .map((row) => {
      const id = row[idx.id];
      const status = String(row[idx.status] || '').trim();
      const firstName = String(row[idx.firstName] || '').trim();
      const lastName = String(row[idx.lastName] || '').trim();
      const fullName = [firstName, lastName].filter(Boolean).join(' ').trim();
      const rate = toNumber(row[idx.rate]);
      const bed = String(row[idx.bed] || '').trim();
      return { id, status, fullName, rate, bed };
    })
    .filter((r) => r.id !== '' && r.id != null)
    .filter((r) => r.status === '1')
    .sort((a, b) => String(a.fullName).localeCompare(String(b.fullName)));

  let unmatchedProvidedNames = [];
  if (hasMemberFilter) {
    clients = clients.filter((client) =>
      providedMemberNames.some((providedName) =>
        clientMatchesProvidedName(client.fullName, providedName)
      )
    );

    unmatchedProvidedNames = providedMemberNames.filter(
      (providedName) =>
        !clients.some((client) =>
          clientMatchesProvidedName(client.fullName, providedName)
        )
    );
  }

  return { clients, unmatchedProvidedNames };
}

function writeBudgetWorkbook(clients) {
  const wb = XLSX.utils.book_new();

  const reportInfo = [
    'Report Type',
    'Monthly Census Budget/Deficit (Status 1 Only)',
    'As Of Date',
    asOfDate,
    'Report Month',
    reportMonth,
  ];

  const header = [
    'Client ID',
    'Client Name',
    'Status',
    'Bed',
    'Actual Rate',
    'Target Rate',
    'Variance (Actual - Target)',
    'Deficit (Target - Actual if positive)',
    'Surplus (Actual - Target if positive)',
  ];

  const data = [reportInfo, [], header];
  clients.forEach((client) => {
    data.push([
      client.id,
      client.fullName,
      client.status,
      client.bed,
      client.rate,
      TARGET_RATE,
      null,
      null,
      null,
    ]);
  });

  data.push(['', 'TOTALS', '', '', null, null, null, null, null]);

  const ws = XLSX.utils.aoa_to_sheet(data);
  const firstDataRow = 4;
  const lastDataRow = clients.length + 3;
  const totalRow = lastDataRow + 1;

  for (let row = firstDataRow; row <= lastDataRow; row += 1) {
    ws[`G${row}`] = { t: 'n', f: `E${row}-F${row}` };
    ws[`H${row}`] = { t: 'n', f: `MAX(0,F${row}-E${row})` };
    ws[`I${row}`] = { t: 'n', f: `MAX(0,E${row}-F${row})` };
  }

  ws[`E${totalRow}`] = { t: 'n', f: `SUM(E${firstDataRow}:E${lastDataRow})` };
  ws[`F${totalRow}`] = { t: 'n', f: `SUM(F${firstDataRow}:F${lastDataRow})` };
  ws[`G${totalRow}`] = { t: 'n', f: `SUM(G${firstDataRow}:G${lastDataRow})` };
  ws[`H${totalRow}`] = { t: 'n', f: `SUM(H${firstDataRow}:H${lastDataRow})` };
  ws[`I${totalRow}`] = { t: 'n', f: `SUM(I${firstDataRow}:I${lastDataRow})` };

  ws['!cols'] = [
    { wch: 10 },
    { wch: 24 },
    { wch: 8 },
    { wch: 8 },
    { wch: 12 },
    { wch: 12 },
    { wch: 26 },
    { wch: 34 },
    { wch: 34 },
  ];

  XLSX.utils.book_append_sheet(wb, ws, 'Monthly Status1');

  const printHeader = ['Client ID', 'Client Name', 'Status', 'Bed', 'Rate'];
  const printData = [
    ['Census Print Report', '', '', '', ''],
    ['As Of Date', asOfDate, '', '', ''],
    ['Report Month', reportMonth, '', '', ''],
    [],
    printHeader,
  ];

  clients.forEach((client) => {
    printData.push([client.id, client.fullName, client.status, client.bed, client.rate]);
  });

  const printTotalRow = printData.length + 1;
  const printStartDataRow = 6;
  const printEndDataRow = printStartDataRow + clients.length - 1;

  printData.push([]);
  printData.push(['Summary', '', '', '', '']);
  printData.push(['Members In Census', clients.length, '', '', '']);
  printData.push(['Rate Column Total', '', '', '', null]);
  printData.push(['Members x 1500', '', '', '', null]);
  printData.push(['Difference (Rate Total - Members x 1500)', '', '', '', null]);

  const pws = XLSX.utils.aoa_to_sheet(printData);

  const summaryRateTotalRow = printTotalRow + 3;
  const summaryTargetRow = printTotalRow + 4;
  const summaryDiffRow = printTotalRow + 5;

  pws[`E${summaryRateTotalRow}`] = { t: 'n', v: 0, f: `SUM(E${printStartDataRow}:E${printEndDataRow})` };
  pws[`E${summaryTargetRow}`] = { t: 'n', v: 0, f: `B${printTotalRow + 2}*${TARGET_RATE}` };
  pws[`E${summaryDiffRow}`] = { t: 'n', v: 0, f: `E${summaryRateTotalRow}-E${summaryTargetRow}` };

  pws['!cols'] = [
    { wch: 12 },
    { wch: 26 },
    { wch: 10 },
    { wch: 10 },
    { wch: 14 },
  ];

  XLSX.utils.book_append_sheet(wb, pws, 'Print Census');
  XLSX.writeFile(wb, OUTPUT_PATH);
}

const { clients, unmatchedProvidedNames } = buildRows();
writeBudgetWorkbook(clients);

console.log(
  `Created ${OUTPUT_PATH} for ${clients.length} monthly census clients (status 1 only${hasMemberFilter ? ', filtered by provided current-member list' : ''}).`
);
if (unmatchedProvidedNames.length) {
  console.log(`Unmatched provided names: ${unmatchedProvidedNames.join(', ')}`);
}