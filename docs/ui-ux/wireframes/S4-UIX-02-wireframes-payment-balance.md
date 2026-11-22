# S4-UIX-02 — Payment Balance Wireframes

Low-fidelity, grayscale structure-only wireframes based on `PentadERP_index (FINAL).html` and its inline sales/payment handlers. The layouts follow `docs/ui-ux/S1-UIX-01-design-system.md`; no color values are shown below.

**Notation:** `[P]` means **PROPOSED (not in reference)**. `[N]` means **NOT BUILT YET**. "Required?" indicates whether a field or action is required.

---

## 1. Record Payment Form

**Purpose:** Record a payment against a sale transaction. Shows total, paid so far, and remaining balance.

**Layout:**

```text
+--------------------------------------+
| [1] Close                              |
| [2] Record Payment                     |
|                                        |
| [3] Sale Details                       [4] X   |
| Transaction T-001                      Sale Date: 2026-11-20 |
|                                        |
| [5] Total: $1,250.00                   [6] Paid: $800.00 |
|                                        |
| [7] Remaining: $450.00                 |
|                                        |
| [8] OR No.                   [9] Payment Date   [10] Amount   |
|     +------------------+ +-----------+ +--------+       |
|     |                | |           | |        |       |
|     +------------------+ +-----------+ +--------+       |
|                                        |
| [11] Save Payment          [12] Cancel    |
+--------------------------------------+
```

**Numbered annotations:**

1. **Close button.** **Required?** N/A. Closes the form without saving.
2. **Record Payment button.** **Required?** N/A. Primary action; records the payment and closes the form.
3. **Sale details display.** **Required?** N/A. Shows transaction number, sale date, and read-only sale details.
4. **Close icon (X).** **Required?** N/A. Closes the details section.
5. **Total amount.** **Required?** N/A. Read-only; total sale amount from the sale record.
6. **Paid so far.** **Required?** N/A. Read-only; cumulative payments recorded against this sale.
7. **Remaining balance.** **Required?** N/A. Calculated as total - paid; displayed prominently.
8. **OR No.** **Required?** Yes. Origin receipt number from the payment. Text input.
9. **Payment Date.** **Required?** Yes. Date input, pre-filled with today's date (`config.today`). **[P]** Follows the date field pattern: `py-2.5`, `rounded-xl`, `bg-white`/`dark:bg-slate-950/50`, border `gray-200`/`dark:bg-slate-800/50`.
10. **Amount.** **Required?** Yes. Number input, min 0.01, step 0.01. **[P]** Amount being paid. Follows the number input pattern.
11. **Save Payment button.** **Required?** N/A. Primary action; validates amount ≤ remaining, records payment, recalculates balance, and closes the form.
12. **Cancel button.** **Required?** N/A. Closes without saving.

**Role/state variants:**

- **Add payment right shown:** Record Payment button visible; form accessible; OR No., Payment Date, and Amount fields enabled.
- **No Add payment right:** Record Payment button hidden. Form not accessible.
- **Overpayment attempt:** Inline error: "Payment amount exceeds remaining balance. Please enter a valid amount." Field `border-red-500`/`dark:border-red-600` with `focus:ring-2 focus:ring-red-500`/`dark focus:ring-red-600`.
- **Missing-amount error:** Inline error: "Payment amount is required." Field validation using HTML `required` attribute.
- **No-right variant:** Record Payment button hidden; no form presented.

**Navigation:**

- Record Payment → validates, saves, refreshes sale-details dialog, recalculates total/paid/balance. Close → dismiss form.
- Overpayment correction → user reduces amount and re-submits.
- Missing amount → browser/HTML validation prevents submit; inline error message appears.
## 2. Payments List Per Sale

**Purpose:** List all payments recorded against a sale, with receipt numbers, dates, and amounts.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| [1] SALE DETAILS                               [2] X                                          |
|                                                                            |
| [3] Transaction T-001 | Payment Tracking                                     |
|                                                                            |
| Payment summary:                                                           |
| Total: $1,250.00    |  Paid: $800.00    | Balance: $450.00                           |
| Status: Pending                                                       |
|                                                                            |
| Receipt No | Payment Date | Amount                                       |
| ---------- | ------------ | ------------                                   |
| R-001      | 2026-11-15     | $300.00                                        |
| R-002      | 2026-11-20     | $500.00                                        |
|                                        [3] Add Payment Button (hidden without right) |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Dialog eyebrow, "SALE DETAILS".** **Required?** N/A.
2. **Close icon.** **Required?** N/A. Closes without saving.
3. **Transaction display.** **Required?** N/A. Shows transaction number and reference.
4. **Payment summary area.** **Required?** N/A. Shows total, paid, balance, and status.
5. **Payments table header row.** **Required?** N/A. Columns: Receipt No, Payment Date, Amount.
6. **Payment table data row.** **Required?** N/A. One row per payment recorded.
7. **Add Payment button.** **Required?** N/A. Shown only with Add payment right. Opens the Record Payment form.

**Role/state variants:**

## 3. Balance Per Transaction

**Purpose:** Show the payment status and balance for a single transaction, categorizing as Unpaid, Partial, or Paid.

**Layout:**

```text
+--------------------------------------+
| Transaction T-001                    |
| Sale Date: 2026-11-20                |
| Customer: Acme Corp                    |
|                                        |
| Balance Status: UNPAID                 [1] Details / Payments button |
|                                        |
| Total: $1,250.00                                                    |
| Paid: $0.00                                                         |
| Remaining: $1,250.00                                                |
|                                        |
| Status badge: [PENDING]                                              |
| (amber-500/10 background, amber-500 text)                           |
|                                        |
| OR No. | Payment Date | Amount (if any)                       |
| -------| ------------ | ------------                           |
|        |              |                                          |
+--------------------------------------+
```

**Numbered annotations:**

1. **Transaction identifier.** **Required?** N/A. Transaction number T-001.
2. **Sale date and customer.** **Required?** N/A. Read-only display.
3. **Balance status label.** **Required?** N/A. Shows UNPAID / PARTIAL / PAID with appropriate color badge.
4. **Details / Payments button.** **Required?** N/A. Shown per user rights (Sale Detail right). Opens sale-details dialog with payment tracking.
5. **Total amount.** **Required?** N/A. Read-only.
6. **Paid amount.** **Required?** N/A. Cumulative payments recorded.
7. **Remaining balance.** **Required?** N/A. Total minus paid.
8. **Status badge.** **Required?** N/A. Colored pill indicating current status. Active: `emerald-500/10` with `emerald-500` text. Pending: `amber-500/10` with `amber-500` text. Blocked: `red-500/10` with `red-500` text.

**Balance classification:**

- **Unpaid:** Paid = 0.00, Remaining = Total. Status badge: UNPAID (amber).
- **Partial:** Paid > 0.00 and Paid < Total. Remaining > 0.00. Status badge: PARTIAL (amber).
- **Paid:** Paid ≥ Total. Remaining = 0.00. Status badge: PAID (emerald).

**Role/state variants:**

- **User:** Balance status shown; no tabs, no Status/Stamp columns. Details button visible per module rights.
- **Admin/Superadmin:** Full balance details including Status and Stamp columns (shown in table view but not in this compact view).
- **Deleted sale:** Balance shown statically; no Add Payment button; status reflects deleted state.

**Navigation:**

- Details / Payments → opens sale-details dialog. Click balance status → optional drill-down (not in scope).
- **Add payment right shown:** Add Payment button visible; form accessible.
- **No Add payment right:** Add Payment button hidden; "Coming soon" state if module not built.
- **Deleted sale:** Payments table displayed read-only; no Add Payment button; Total and Balance displayed statically.
- **No-right variant:** Add Payment button hidden; no payments form accessible.

**Navigation:**

## 4. Balance Per Customer

**Purpose:** Show aggregated payment balances across all transactions for a given customer.

**Layout:**

```text
+--------------------------------------+
| CUSTOMER ACCOUNT SUMMARY              |
| Customer: Acme Corp                    |
|                                        |
| Transaction | Sales Total | Paid | Balance | Status |
| ----------- | ----------- | ---- | ------- | ------ |
| T-001       | $1,250.00   | $300 | $950.00 | Pending|
| T-003       | $2,500.00   | $500 | $2,000.0| Paid   |
| T-007       | $800.00     | $0   | $800.00 | Unpaid |
|                                        |
| Totals: Sales Total: $4,550.00 | Paid: $800.00 | Balance: $3,750.00 |
|                                        |
| [1] Export CSV          [2] Print       [3] Close |
+--------------------------------------+
```

**Numbered annotations:**

1. **Customer name.** **Required?** N/A. Header display.
2. **Transaction column.** **Required?** N/A. Transaction number per row.
3. **Sales Total column.** **Required?** N/A. Total amount of the sale.
4. **Paid column.** **Required?** N/A. Cumulative payments against this transaction.
5. **Balance column.** **Required?** N/A. Sales Total minus Paid.
6. **Status column.** **Required?** **[P]** Status badge per transaction (per role config). For Users: hidden; for Admin/Superadmin: visible with badge.
7. **Totals row.** **Required?** N/A. Aggregated totals across all customer transactions.
8. **Export CSV button.** **Required?** **[P]** Exports the customer balance data as CSV. Shown for Admin/Superadmin with Reports right.
9. **Print button.** **Required?** **[P]** Prints the customer balance summary. Shown per Reports right.
10. **Close button.** **Required?** N/A. Closes the summary.

**Role/state variants:**

- **User:** Balance values shown; Status column hidden (no Status/Stamp per guide facts). No Export/Print buttons.
- **Admin/Superadmin:** Status column visible with badges; Export and Print buttons visible per rights.
- **No rights:** Empty state: "No transactions found for this customer."

**Navigation:**

- Export CSV → downloads CSV file. Print → prints the summary area. Close → dismisses the summary.
- Add Payment → opens Record Payment form. Close → dismiss details dialog.
- Clicking a payment row → optional detail view (not in scope).
## 5. Overpayment and Missing-Amount Errors

**Purpose:** Error states when payment recording fails validation.

### 5a. Overpayment Error

**Layout:**

```text
+--------------------------------------+
| [1] Close                              |
| [2] Record Payment                     |
|                                        |
| [3] Sale Details                       [4] X   |
| Transaction T-001                      Sale Date: 2026-11-20 |
|                                        |
| [5] Total: $1,250.00                   [6] Paid: $800.00 |
|                                        |
| [7] Remaining: $450.00                 |
|                                        |
| [8] OR No.                   [9] Payment Date   [10] Amount   |
|     +------------------+ +-----------+ +--------+       |
|     |                | |           | |        |       |
|     +------------------+ +-----------+ +--------+       |
|                                        |
| **ERROR: Payment amount exceeds remaining balance**    |
| Please enter an amount ≤ $450.00.                       |
|                                        |
| [11] Save Payment          [12] Cancel    |
+--------------------------------------+
```

**Numbered annotations (overrides):**

- **7a.** **Error inline text.** **Required?** N/A. Red-tinted error message below the Amount field: "Payment amount exceeds remaining balance. Please enter a valid amount." Styled with `border-red-500`/`dark:border-red-600` and `focus:ring-2 focus:ring-red-500`/`dark focus:ring-red-600`.
- **11a.** **Save button disabled.** **Required?** N/A. Primary action is disabled until the amount is corrected.

### 5b. Missing-Amount Error

**Layout:**

```text
+--------------------------------------+
| [1] Close                              |
| [2] Record Payment                     |
|                                        |
| [3] Sale Details                       [4] X   |
| Transaction T-001                      Sale Date: 2026-11-20 |
|                                        |
| [5] Total: $1,250.00                   [6] Paid: $800.00 |
|                                        |
| [7] Remaining: $450.00                 |
|                                        |
| [8] OR No.                   [9] Payment Date   [10] Amount   |
|     +------------------+ +-----------+ +--------+       |
|     |                | |           | |        |       |
|     +------------------+ +-----------+ +--------+       |
|                                        |
| **ERROR: Amount is required.**                           |
| Please enter a payment amount.                            |
|                                        |
| [11] Save Payment          [12] Cancel    |
+--------------------------------------+
```

**Numbered annotations (overrides):**

- **10a.** **Amount field `border-red-500`/`dark:border-red-600`.** **Required?** N/A. Field border turns red to indicate error.
- **Error text.** **Required?** N/A. "Amount is required." displayed below the field.

**Role/state variants:**

- **No-right variant:** Errors not shown (form not accessible).
- **User role:** Errors shown per normal validation.
## 6. No-Right Variant

**Purpose:** Show the payment UI for a user without the Add payment right.

**Record Payment Form - No-Right Variant:**

```text
+--------------------------------------+
| (No payment actions available)       |
|                                        |
| Sale T-001 | Total: $1,250.00 | Paid: $800.00 |
|                                        |
| Remaining: $450.00                     |
|                                        |
| No right to record payments.           |
| Contact Superadmin if you need this access. |
+--------------------------------------+
```

**Payments List Per Sale - No-Right Variant:**

```text
+--------------------------------------------------------------------------------+
| Sale T-001 | Payment Tracking                                                       |
|                                                                        |
| Total: $1,250.00    |  Paid: $800.00    | Balance: $450.00                           |
| Status: Pending                                                       |
|                                                                        |
| Receipt No | Payment Date | Amount                                       |
| ---------- | ------------ | ------------                                   |
| (no payments recorded)                                           |
|                                                                        |
| (Add Payment button hidden)                                          |
+--------------------------------------------------------------------------------+
```

**Balance Per Transaction - No-Right Variant:**

```text
+--------------------------------------+
| Transaction T-001                    |
| Balance Status: —                    |
| (no payment rights)                  |
|                                        |
| Total: $1,250.00                                                    |
| Paid: —                                                             |
| Remaining: —                                                        |
+--------------------------------------+
```

**Role/state variants:**

- **User without Add payment right:** All payment actions hidden; informational message shown instead.
- **Admin/Superadmin with right:** All payment actions visible; normal UI.
- **User with Add payment right:** Full payment UI accessible.

**Navigation:**

- No-right variant: No navigation to payment forms; informational text only.
## Gaps & Assumptions

- The reference HTML/sales-list.js has payment tracking within the sale-details dialog (sections 7–8 of S4-UIX-01), but a standalone "Payment Balance" screen is **PROPOSED (not in reference)**.
- OR number format and validation rules are **PROPOSED (not in reference)**; assumed to be alphanumeric receipt identifier.
- Overpayment and missing-amount error styles follow the reference's `border-red-500`/`dark:border-red-600` and focus ring patterns.
- The 36-right matrix gates UI visibility: Sales 7 (incl. Sale Detail) governs Details/Payments buttons; Add payment right is a separate gate for Record Payment form.
- Balance classification (Unpaid/Paid/Partial) uses the same logic as sales list: `balance = total - payments`; a sale is **Paid** when `paid >= total`.
- No future-dated payments are supported in this wireframe; payment date defaults to `config.today`.
- Customer balance aggregation (Section 4) is **PROPOSED (not in reference)**; the reference only shows per-transaction payment tracking.
- Print/Save as PDF for customer balances uses the same 7-report rights structure from guide facts.
- No-right variant states are new documentation; the reference hides buttons via `currentActions` checks but does not document the informational state.
- Employee separation date (left the company) is different from deleted; salary and job history hidden without View Job History (Data Privacy Act RA 10173) — noted for cross-module awareness.
- Current price = latest effective date not in the future; a sale line uses the price on the SALE DATE.
- 7 reports with date range + Top N, per-report rights, Print/Save as PDF — separate from payment wireframes.
- Audit viewer: Superadmin only — separate from payment wireframes.