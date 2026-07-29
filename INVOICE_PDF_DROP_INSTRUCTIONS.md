# Member Invoice PDFs — Drop Instructions

## What this does
Members will be able to view invoices in the portal once PDFs are placed into the correct folders and the manifest file is regenerated.

This setup is intentionally simple:
- Your accounting program exports invoice PDFs.
- You save/copy those PDFs into a known folder.
- A script generates a single JSON manifest (`invoices/invoices.json`) that the portal reads.

## Where to drop PDFs (required)
Drop PDFs into these folders (relative to this repo):
- `horizon-portal/invoices/unpaid/`  (new / unpaid invoices)
- `horizon-portal/invoices/paid/`    (paid invoices)

If you’re exporting on another computer/server, the *same folder structure* needs to exist wherever the portal files are hosted.

## Required filename rules (so the portal can match invoices to a member)
Each PDF filename **must include**:
- `MID<memberId>` (member’s numeric ID)
- `INV<invoiceNumber>` (any invoice identifier from your accounting system)

Filename must end in `.pdf`.

### Example filenames (recommended)
Unpaid:
- `MID1234_INV10023_DUE03-31-2026_AMT450.00.pdf`

Paid:
- `MID1234_INV10023_PAID04-02-2026_AMT450.00.pdf`

### Optional tokens (if you want them displayed)
You can include these tokens anywhere in the filename:
- `_DUEMM-DD-YYYY`
- `_PAIDMM-DD-YYYY`
- `_AMT123.45`

Legacy note: the generator also accepts the older `YYYY-MM-DD` token format, but it will normalize it to `MM-DD-YYYY` in the manifest.

## Generate the manifest (required)
After dropping PDFs, regenerate the manifest:

1. Open a terminal in `horizon-portal/backend/`
2. Run:

- `npm run generate:invoices`

This writes/updates:
- `horizon-portal/invoices/invoices.json`

## Quick verification
- Confirm a PDF is reachable by URL:
  - If portal is served from the backend server: `/invoices/unpaid/<yourfile>.pdf`
  - If you’re browsing via a static server from repo root: `/horizon-portal/invoices/unpaid/<yourfile>.pdf`

## Troubleshooting
- If an invoice does not show up for a member, check the filename includes both `MID` and `INV`.
- If the generator prints a warning about files not matching rules, rename those PDFs.
