# S4-UIX-04 — Hi-fi Mockups and Developer Handoff

Static artifacts, not code. Shared Tailwind config + theme CSS + extracted logo. Light/dark theme toggle only.

## Shared files

- `docs/ui-ux/mockups/shared/tailwind-config.js` — Tailwind CDN: dark mode, DM Sans, remapped colors.
- `docs/ui-ux/mockups/shared/theme.css` — Reference CSS: body, glass-panel, glow-hover, modal-overlay, scrollbar, logo, pill-button.
- `docs/ui-ux/assets/pentad-logo.png` — PNG from reference `.pentad-logo` data URI.

Load Tailwind, Google Fonts DM Sans, Font Awesome 6.5.1 from same CDNs. Initial mode dark (`<html class="dark">`), theme toggle switches root class.

## Per-screen handoff (condensed)

### sales-list.html

- Header: breadcrumb, role badge, theme toggle. Search pill, New Sale button (Sales Add right gated).
- Table: Txn No, Sale Date, Customer, Salesperson, Total, Actions. Rows: T-001 $1,250, T-002 $800, T-003 $2,500.
- Status tabs (Active/Inactive/All) with count chips: Admin/Superadmin see all + counts; User sees active-only, no tabs.
- Action columns: Details/Delete per rights; hidden from User. No-right: search/New Sale hidden, tabs hidden, actions hidden.
- Dark mode: starts dark, toggles root `.dark`. Paired light/dark inputs.
- Tokens: `font-sans`, `rounded-2xl`, `p-4`, `focus:ring-2 focus-brand-600`, `brand-600`/`brand-500` hover. Tab pill: `gap-0.35rem`, `padding 0.45rem 0.8rem`, `font-size 0.68rem`, `font-weight 800`. Active: `brand-600` white. Inactive: `gray-200`/`dark:bg-slate-800/10` muted. Count chips: `p-1`, `text-[10px] font-bold uppercase tracking-wider`, `brand-500/10`/`brand-500` light/dark.
- Right-gated: User: active-only, no tabs, no actions. Superadmin/Admin: tabs + count chips + action columns.

### sale-form.html

- Read-only auto-numbered Trans No, Sale Date date input, Customer dropdown (active only), Salesperson dropdown (active only).
- Required: Sale Date, Customer, Salesperson. Close/cancel leaves list unchanged.
- Create Sale button hidden without Sales Add right.
- Dark mode: paired `dark:` classes. Tokens: `max-w-md`, `rounded-3xl`, `p-8`, label `text-[10px] uppercase tracking-wider`, input `rounded-xl`/`px-4 py-2.5`, `focus:ring-2 focus-brand-500`, brand button, DM Sans.
- Proposed: OR number format, error styles.

### sale-line-items.html

- Sale date display, total balance, line items table (Product, Qty, Unit Price as of sale date, Line Total, Actions).
- Unit price from price history on sale date (latest effective <= sale date). Future dates ignored.
- Add Line Item: Sale Add right gated. Product dropdown from active products with price history. "No price on this date" warning if none.
- Edit/Delete per line right. No-right: Add/Edit/Delete hidden; view-only.
- Dark mode: shared theme toggle, paired light/dark classes.
- Tokens: `rounded-3xl`, `p-6`, table `text-xs`, uppercase headers, `p-4` cells, `divide-y`, primary/outline/soft actions.
- Proposed: balance = total - payments; price lookup on sale date.

### payment-form.html

- Close, sale details, OR No. text input, Payment Date date input (today), Amount number input, Save Payment/Cancel.
- Overpayment/missing-amount errors. No-right: Record Payment button hidden.
- Dark mode: paired `dark:` classes. Tokens: `rounded-3xl`, `p-7`, label `text-[10px] uppercase tracking-wider`, input `rounded-xl`/`py-2.5`, `bg-white`/`dark:bg-slate-950/50`, border `gray-200`/`dark:bg-slate-800/50`, `focus:ring-2 focus-brand-500`/`dark focus:ring-red-600`, primary/secondary buttons, DM Sans.
- Proposed: OR number format (alphanumeric).

### balance-view.html

- Transaction T-001, Sale Date: 2026-11-20, Customer: Acme Corp. Balance Status badge (UNPAID/PARTIAL/PAID).
- Total: $1,250.00, Paid: $800.00, Remaining: $450.00. Payments table (Receipt No, Date, Amount).
- Balance classification: Unpaid (Paid=0), Partial (0<Paid<Total), Paid (Paid>=Total).
- User: balance status shown, no tabs/Stamp. Admin/Superadmin: full details including Status/Stamp.
- Dark mode: theme toggle, paired light/dark classes.
- Proposed: standalone screen; OR alphanumeric; balance classification logic.

### reports.html

- Report picker: vertical list (Product Master List, Active Employees, All Employees, Employee Job History, Top Customers, Top Products, Top Sales). Superadmin/Admin see all 7; User sees only Active Employees.
- Print/Save as PDF per-report rights. Print stylesheet: reference's `@media print` blocks — recommend visibility `hidden`.
- Sample table: Active Employees. 7 reports with date range + Top N, per-report rights, Print/Save as PDF.
- Dark mode: theme toggle, paired light/dark classes.
- Tokens: `report-picker-button` pill-shaped, `brand-600` active, `gray-200`/`dark:bg-slate-800/50` inactive. Table `text-xs`, uppercase headers, `p-4` cells, `divide-y`, `overflow-x-auto`.
- Proposed: date range filters inclusive; Top N 1-100 default 10; rank per Figure 28; Print/Save as PDF per report rights.

### audit-viewer.html

- Superadmin-only: filters (User, Event Type, Date Range), audit log table, pagination, empty state. Print/Save as PDF (Superadmin only).
- Dark mode: inherited root class, shared CSS dark surfaces/text/borders.
- Tokens: `modal-content`, `glass-panel`, `rounded-3xl`, `p-8`, `max-w-2xl`, `max-h-80`, `overflow-y-auto`, `space-y-4`, `rounded-2xl` groups.
- Proposed: Superadmin only; filters; pagination; Duration column.

## Proposed items

- Right-gated visibility for User across all screens
- Admin User Management: hide Superadmin, limit management to Users
- Block/Unblock, Approve pending, Designate Admin
- Rights All/None and last-Superadmin guard
- Report-specific and Sale Detail rights in Rights dialog

Each proposed element tagged "Proposed."