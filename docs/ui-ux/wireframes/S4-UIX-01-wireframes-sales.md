# S4-UIX-01 — Sales List & Details Wireframes

---
Low-fidelity, grayscale structure-only wireframes based on `PentadERP_index (FINAL).html` and its inline sales handlers. The layouts follow `docs/ui-ux/S1-UIX-01-design-system.md`; no color values are shown below.

**Notation:** `[P]` means **PROPOSED (not in reference)**. `[N]` means **NOT BUILT YET**. "Required?" indicates whether a field or action is required.
## 1. Sales List

**Purpose:** Search and manage sales transactions; view transaction details, line items, and payments.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / SALES MODULE                                                   [1] role    |
|                                                                            [2] theme    |
+--------------------------------------------------------------------------------+
|                                                              [3] Search    |
|                                                              [4] New Sale    |
+--------------------------------------------------------------------------------+
| +----------------------------------------------------------------------------+ |
| | [5] Transaction No | Sale Date | Customer | Salesperson | Total |        | |
| | -------------------- | --------- | --------- | ------------ | ----- | | [6]      |
| | T-001                | 2026-11-20| Acme Corp   | Juan Dela Cruz| $1,250.00 | | [7] Details |
| | T-002                | 2026-11-18| Banco Inc   | Maria Santos  | $800.00   | | [7] Details |
| | T-003                | 2026-11-15| Sony Philippines| Pedro Reyes  | $2,500.00 | | [7] Details |
| | ...                                                                | |           |
| +----------------------------------------------------------------------------+ |
|                                                              [8] Active 12   |
|                                                              [9] Inactive 3   |
|                                                             [10] All 15      |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Header breadcrumb and role badge.** **Required?** N/A. Reuses the built `PentadERP / WORKSPACE` breadcrumb and top-right role badge.
2. **Theme toggle.** **Required?** N/A. Reuses the built light/dark theme control.
3. **Module eyebrow/pill, "SALES MODULE".** **Required?** N/A.
4. **Page title and subtitle.** **Required?** N/A. "Sales". Subtitle: "Search sales transactions and create a new sale."
5. **Search field.** **Required?** N/A. Filters transaction No, sale date, customer name, or salesperson as text is entered. **[P]** Follows the search pill pattern: magnifying glass icon, `rounded-full` border-radius, `gray-200`/`dark:bg-slate-800/50` background, `brand-600` focus ring.
6. **New Sale action.** **Required?** N/A. Shown only with Sales Add right. Opens the New Sale form (sale-dialog).
---
7. **Details action.** **Required?** N/A. Shown for non-deleted rows when user has Sale Detail right. Opens sale-details dialog. Label: "Details / Payments" when user has both view and payment rights, else "Payments".
## 2. Sales List: No-Right Variants

---
**Scenario:** User without Sales Add/Sale Detail rights.
## 3. New Sale Form

---
**Purpose:** Create a new sale transaction. The Trans No is auto-numbered and read-only.
## 4. Sale Details Dialog (Line Items)

**Purpose:** Add, edit, and delete line items for a sale. Each line uses the price on the SALE DATE.

**Layout (initial view with existing line items):**

```text
+--------------------------------------------------------------------------------+
| [1] SALE DETAILS                               [2] X            |
|                                                |
| [3] Sale date: 2026-11-20                      [4] Total: $1,250.00 |
|                                                |
| [5] Line items:                                  [6] Balance: $1,250.00 |
|                                                |
| | [7] Product | Quantity | Unit Price (as of sale date) | Line Total | Actions | |
| | --------- | -------- | ---------------------------- | ---------- | --------- | |
| | P-001     | 3        | $45.00                       | $135.00    | [8] Edit  | |
| | P-002     | 2        | $50.00                       | $100.00    | [8] Delete| |
| +--------------------------------------------------------------------------------+
|                                [9] Add Line Item    [10] Balance summary      |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Dialog eyebrow, "SALE DETAILS".** **Required?** N/A.
2. **Close icon.** **Required?** N/A. Closes without saving.
3. **Dialog title.** **Required?** N/A. "Sale line items — T-001".
4. **Sale date display.** **Required?** N/A. Shows the sale date in "Sale date: YYYY-MM-DD" format.
5. **Total.** **Required?** N/A. Sum of all line totals. Displayed as formatted currency.
6. **Balance.** **Required?** N/A. Total minus total payments. Displayed as formatted currency. **[P]** Balance = total - payments; initially equal to total when no payments recorded.
7. **Line items table.** **Required?** N/A. Columns: Product, Quantity, Unit Price (as of sale date), Line Total, Actions. Unit price is derived from the price effective on the sale date (latest effective-dated price whose effectiveDate <= sale date). **[P]** The reference types the Trans No and uses the latest price; this wireframe documents that sale lines use the price on the SALE DATE.
8. **Actions column.** **Required?** N/A. Right-aligned Edit/Delete buttons per user rights; hidden when matching right is absent (no-right variant).
9. **Add Line Item.** **Required?** N/A. Shown only with Sale Add right. Hidden when no active products have a price effective on the sale date; shows "no price on this date" warning.

**Line item row layout:**

```text
+------------------------------------------------------+
| P-001          | 3        | $45.00         | $135.00   | [Edit] [Delete] |
+------------------------------------------------------+
```

**Add Line Item form (opened from button 9):**

```text
+--------------------------------------------------+
| [1] SALE DETAILS                               [2] X            |
|                                                |
| [3] Product                [4] Choose product... |
|                                                |
| [4] Quantity                         [5] 1         |
|                                                |
| [5] Unit Price (as of sale date)   [6] $45.00   |
---
|      (read-only, computed from price history)    |
## 5. Sale Details Dialog: No-Right Variants

---
**Scenario:** User without Sale Detail rights.
## 6. Soft Delete / Restore

---
**Purpose:** Soft-delete a sale transaction (move to Inactive status). Restore a deleted transaction.
## 7. Sale Details Dialog: Payment Tracking

---
**Purpose:** Record and track payments against a sale.
## 8. Gaps & Assumptions

| Topic | Available source | Gap or decision |
|---|---|---|
| Reference types Trans No and uses latest price | `my-web-app/static/sales-list.js` function `renderSales`; reference HTML `renderSales` handler | Wireframe documents that Trans No is auto-numbered read-only and sale lines use the latest effective price on the SALE DATE (not today's date). |
| Search/filter, status tabs, restore | `my-web-app/templates/sales_list.html`; `my-web-app/static/sales-list.js` | Search is present; status tabs per role config; restore marked [P] per guide facts. |
| Price on sale date rule | `my-web-app/static/sales-list.js` function `updateSaleDetailPrice`; price lookup logic | Wireframe proposes: latest active effective-dated price whose effectiveDate <= sale date; future rows do not become current. |
| No-right variants | `my-web-app/static/sales-list.js`; rights checks via `currentActions` | Buttons hidden when matching right is absent; design uses `is-admin` flag + module-specific rights config from 36-right matrix. |
| Customer/employee dropdowns from active only | `my-web-app/static/sales-list.js` function `loadSaleOptions` | Dropdowns populated from `/api/sales/options`; only active customers/employees shown. |
| 36 rights: Customer 3; Product 6 (incl. prices); HR 13 (incl. View/Add/Edit/Delete Job History); Sales 7 (incl. Sale Detail); Reports 7 | Design system and guide facts | Rights matrix gates respective UI elements; UI shows/hides elements conditionally based on `is_admin` flag and module-specific rights. |
| Employee separation date different from deleted; salary and job history hidden without View Job History (Data Privacy Act RA 10173) | Guide facts | Not directly relevant to sales wireframe; noted for cross-module awareness. |
| 7 reports with date range + Top N, per-report rights, Print/Save as PDF | Guide facts | Separate report wireframes; not built into this sales wireframe. |
| Audit viewer: Superadmin only | Guide facts | Separate audit viewer; not built into this sales wireframe. |

---

**Layout (summary area):**

```text
+------------------------------------------------------+
| Total: $1,250.00    |  Paid: $800.00    | Balance: $450.00 |
| Status: Pending                                   |
+------------------------------------------------------+
```

**Add Payment form (opened from "Record Payment" button):**

```text
+--------------------------------------------------+
| [1] SALE DETAILS                               [2] X            |
|                                                |
| [3] Payment Date                 [4] today’s date|
|                                                |
| [4] Amount                           [5] $0.00   |
|                                                |
|                                                |
| [6] Cancel             [7] Record Payment        |
+--------------------------------------------------+
```

**Numbered annotations:**

1–2. **Dialog eyebrow and close.** Reuse shared modal pattern.
3. **Payment Date.** **Required?** Yes. Default: today's date. **[P]** Date field, pre-filled with `config.today`.
4. **Amount.** **Required?** Yes. Number input, min 0.01, step 0.01. **[P]** Amount paid.
5. **Cancel.** **Required?** N/A. Closes without saving.
6. **Record Payment.** **Required?** N/A. Primary action; records the payment and refreshes the details dialog, recalculating balance and status.

**Payment summary (inside details dialog, below line items):**

```text
+------------------------------------------------------+
| Total: $1,250.00    |  Paid: $800.00    | Balance: $450.00 |
| Status: Pending                                   |
+------------------------------------------------------+
```

Below the summary, a payments table lists receipt No, payment Date, and Amount per payment.

**Role/state:**

- **Add payment right:** Record Payment button visible; form accessible.
- **No Add payment right:** Record Payment button hidden.

**Navigation:** Record Payment → saves and refreshes. Close → dismiss form.

**Layout - Confirm Dialog:**

```text
+------------------------------------------+
| [1] !                                    |
| [2] Please confirm                       |
| [3] Move sale T-001 to Inactive?          |
|                                              |
| [4] Cancel       [5] Confirm             |
+------------------------------------------+
```

**Numbered annotations:**

1. **Info icon.** **Required?** N/A. Warning triangle.
2. **Please confirm.** **Required?** N/A. Static text.
3. **Move sale T-001 to Inactive?** **Required?** N/A. Dynamic with transaction No.
4. **Cancel.** **Required?** N/A. Closes without action.
5. **Confirm.** **Required?** N/A. Soft-deletes the sale and refreshes the list.

**Role/state variants:**

- **Admin/Superadmin:** Can delete and restore sales. Delete moves sale to Inactive status; Restore returns it to Active.
- **User:** Cannot see Delete/Restore actions; active-only view; no tabs visible.
- **Deleted rows.** **Required?** N/A. When a sale is soft-deleted, it is marked `isDeleted` and shaded (bg-gray-100/`dark:bg-slate-950/50`). In the list, deleted rows show "Restore" button instead of "Delete" for Admin/Superadmin with Restore right. Deleted rows have Status = "Inactive" and Stamp = "DELETED + user + datetime" for Admin/Superadmin; Users see "—" only.
- **Restore.** **Required?** N/A. Shown on deleted rows only to an administrator or superadmin with Restore right. Restores the sale to Active status immediately after permission/API confirmation. **[P]** Shaded background with Restore button; text: "Restore".

**Navigation:** Delete → confirm-delete dialog; success shows toast and refreshes list. Restore → restores sale to Active; closes deleted view; refreshes list.

- Add Line, Edit, Delete buttons hidden from all line items.
- Line items displayed read-only: Product and Quantity visible, Unit Price and Line Total shown but not editable.
- No "no price on this date" warning (no add capability).
- Total and Balance displayed statically (cannot be changed).
|                                                |
|                                                |
| [7] Cancel             [8] Add Line                |
+--------------------------------------------------+
```

**Numbered annotations for add form:**

1–2. **Dialog eyebrow and close.** Reuse the shared modal pattern.
3. **Dialog title.** "Add Line Item — T-001".
4. **Product.** **Required?** Yes. Dropdown of active products with price history. Populated from `currentSaleDetails` or the product catalog. **[P]** Dropdown from active products; only products with a price effective on the sale date should appear; if none, show "no price on this date" warning.
5. **Quantity.** **Required?** Yes. Number input, min 0.01, step 0.01. Default: 1.
6. **Unit Price (as of sale date).** **Required?** Yes, read-only. Display the latest effective-dated price whose effective date is on or before the sale date. If no qualifying price, show "-". **[P]** Computed from price history; does not alter price history.
7. **Cancel.** **Required?** N/A. Closes without saving.
8. **Add Line.** **Required?** N/A. Primary action; validates form and adds the line. Saves the line and refreshes the details dialog, recalculating total and balance.

**Edit Line Item (opened from Edit button 8):**

Same layout as Add Line Item, but pre-filled with the existing detail's product, quantity, and computed unit price. Save changes updates the line and refreshes the details dialog.

**Delete Line Item:**

Confirmed via modal: "Delete the P-001 line item from this sale?" Cancel/Confirm. Removes the line and refreshes the details dialog.

**Role/state:**

- **Sale Detail right shown:** Add Line button visible; Edit/Delete per line visible when user has respective rights.
- **No Sale Detail right:** Add, Edit, Delete buttons hidden; view-only mode for line items.
- **"No price on this date" warning:** Shown when Add Line is clicked and no active product has a price effective on the sale date. Message: "No active products have a price effective on this sale date. Add price to product catalog or select a different date."

**Current-price computation:** [P] The system uses the sale date to look up the latest active effective-dated price whose effective date is on or before the sale date. Future-dated prices do not become current. If no qualifying price exists, display "-".

**Navigation:** Add Line → adds line and refreshes. Edit → opens edit form. Delete → confirm delete. Close → dismiss details dialog. Total and balance recalculate automatically.

**Layout:**

```text
+--------------------------------------------------+
| [1] SALES DETAILS              [2] X             |
|                                                |
| [3] New Sale                                         |
|                                                |
| [4] Trans No: T-001  [read-only, disabled]       |
|                                                |
| [5] Sale Date          [date input]              |
|                                                |
| [6] Customer                   [dropdown]        |
|     Choose customer...                                      |
|                                                |
| [7] Salesperson                [dropdown]        |
|     Choose salesperson...                                   |
|                                                |
|                                                |
| [8] Cancel       [9] Create Sale                   |
+--------------------------------------------------+
```

**Numbered annotations:**

1. **Dialog eyebrow, "SALES DETAILS".** **Required?** N/A.
2. **Close icon.** **Required?** N/A. Closes without saving.
3. **Dialog title.** **Required?** N/A. "New Sale" for create.
4. **Trans No.** **Required?** Yes, read-only, auto-generated. Display format: `T-` followed by sequence number. Shown disabled/grayed. **[P]** The reference types the Trans No; this wireframe makes it read-only and auto-numbered.
5. **Sale Date.** **Required?** Yes. Date field. Pre-filled with today's date (`config.today`). **[P]** The reference uses the sale date to determine the price to apply on line items.
6. **Customer.** **Required?** Yes. Dropdown populated from active customers. **[P]** Dropdown from active customers only (per guide facts: dropdowns from active customers/employees).
7. **Salesperson.** **Required?** Yes. Dropdown populated from active employees. **[P]** Dropdown from active employees only.
8. **Cancel.** **Required?** N/A. Closes without saving.
9. **Create Sale.** **Required?** N/A. Primary action; validates form and creates the sale. **[P]** Button text: "Create Sale"; hidden when user lacks Sales Add right.

**Role/state:**

- **Add right shown:** New Sale button visible; form accessible.
- **No Add right:** New Sale button hidden; "Coming soon" placeholder if module not built.
- **Form validation:** Sale Date, Customer, and Salesperson are required. Close/cancel leaves the list unchanged. Success closes the dialog and refreshes the sales list, opening the sale-details dialog for the new transaction.

**Navigation:** Create Sale → refresh list + open details dialog. Close/cancel → dismiss form.

- New Sale button hidden.
- Details button hidden per row.
- No Status/Stamp columns even for Admin (when rights config denies them).
- Tabs hidden for normal Users; Admin/Superadmin always see tabs.
8–10. **Status tabs (Active/Inactive/All).** **Required?** Admin/Superadmin only. Count chips show total per status. **[P]** Follows the tab pill pattern: `gap-0.35rem`, `padding 0.45rem 0.8rem`, `font-size 0.68rem`, `font-weight 800`. Active tab uses solid `brand-600` with white text; inactive tabs use `gray-200`/`dark:bg-slate-800/10` fill with muted text. Count chips positioned at `p-1` on tab buttons, using `text-[10px] font-bold uppercase tracking-wider` with `brand-500/10` background and `brand-500` text in light mode, `amber-500/10`/`amber-500` in dark mode. Users see active-only with no tabs, no count pills (per guide facts: "User sees active rows only: no Active/Inactive/All tabs, no Status or Stamp columns").
11. **Table.** **Required?** N/A. The required reference fields are Transaction No, Sale Date, Customer, Salesperson, Total, and Actions. Status and Stamp columns are **[P]** because the reference sales table does not show them by default for Users; they are added here only for Admin/Superadmin per the built-app pattern.

**Role/state variants:**

- **Admin/Superadmin:** Active/Inactive/All tabs and Status/Stamp columns are available; actions follow each assigned right. Admins and superadmins have implicit full access in the built app.
- **User:** The list is active-only, status tabs are hidden, Status/Stamp are hidden, and Details depend on assigned module rights. No-right variants hide Details/Edit/Delete buttons.
- **No module rights:** The sales route is unavailable or shows an empty/denied state; no add action is shown.

**Current-price rule:** [N/P] The list shows the Total using the latest effective price whose effective date is on or before the sale date. A sale line uses the price on the SALE DATE (not today's date). If no qualifying price exists, show "-" or "No price on this date" warning.

**Navigation:** Search → filter matching rows. Add → New Sale form. Edit → open sale-details dialog for line items. Details → open sale-details dialog. Delete → confirm soft-delete dialog. Restore → restore immediately after permission/API confirmation.
