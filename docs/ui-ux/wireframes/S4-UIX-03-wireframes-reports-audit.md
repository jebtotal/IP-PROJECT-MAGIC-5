
# S4-UIX-03 — Reports and Audit Wireframes

Low-fidelity, grayscale structure-only wireframes based on `PentadERP_index (FINAL).html` and its inline report handlers. The layouts follow `docs/ui-ux/S1-UIX-01-design-system.md`; no color values are shown below.

**Notation:** `[P]` means **PROPOSED (not in reference)**. `[N]` means **NOT BUILT YET**.

---
## 1. Report Picker

**Purpose:** Shows only the reports the user has the right for; Superadmin/Admin see all 7 reports, User sees only Active Employees.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE                                                   [1] role    |
|                                                                            [2] theme    |
+--------------------------------------------------------------------------------+
|  [1] Product Master List                                                   [3] Search  |
|  [2] Active Employees                                                      [4] New ...  |
|  [3] All Employees                                                         |
|  [4] Employee Job History (employee picker)                               |
|  [5] Top Customers                                                         |
|  [6] Top Products                                                          |
|  [7] Top Sales                                                             |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Header breadcrumb and role badge.** **Required?** N/A. Reuses the built `PentadERP / WORKSPACE` breadcrumb and top-right role badge.
2. **Theme toggle.** **Required?** N/A. Reuses the built light/dark theme control.
3. **Module eyebrow/pill, "REPORTS MODULE".** **Required?** N/A.
4. **Page title and subtitle.** **Required?** N/A. "Reports". Subtitle: "Choose an authorized report. Use Print to print or save the report as PDF."
5. **Report picker area.** **Required?** N/A. Vertical list of report buttons; shown only for reports user has right for. Superadmin/Admin see all 7; User sees only Active Employees. Buttons use `report-picker-button` class, pill-shaped, `brand-600` text when active, `gray-200`/`dark:bg-slate-800/50` inactive. `[P]` Follows the report picker pattern from `static/reports.js`.
6. **No-report message.** **Required?** N/A. Shown when user has no report rights: "You do not have access to any individual reports. Ask an administrator to assign report rights."
7. **Print / Save as PDF button.** **Required?** N/A. Shown per Reports right; when clicked, prints `#reportPrintArea` or saves as PDF. `[P]` Per guide facts: 7 reports with date range + Top N, per-report rights, Print/Save as PDF.

## 2. Reports: Product Master List

**Purpose:** List all products with current unit price; read-only, no filters.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / PRODUCT MASTER LIST                              |
+--------------------------------------------------------------------------------+
| +----------------------------------------------------------+ -------------+ |
| | Product Code | Description | Unit | Current Unit Price          |   [5]         | |
| | ------------ | ----------- | ---- | --------------------------          |             | |
| | P-001        | Product A   | pc   | $12.50                                | [Details]   | |
| | P-002        | Product B   | pc   | $18.00                                | [Details]   | |
| | ...                                                             |               | |
| +----------------------------------------------------------+ -------------+ |
|                                0 row(s).                                      |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Header breadcrumb and title.** **Required?** N/A. "Product Master List".
2. **Table header row.** **Required?** N/A. Columns: Product Code, Description, Unit, Current Unit Price. Uppercase bold `text-[10px] font-bold uppercase tracking-wider` on `gray-50`/`gray-100`.
3. **Table data rows.** **Required?** N/A. Product Code bold, Description, Unit, Current Unit Price formatted as currency PHP. `[P]` Current price = latest effective date not in the future.
4. **Empty state.** **Required?** N/A. Centered "No records found." `p-6` when no products available.
5. **Print / Save as PDF button.** **Required?** N/A. Shown per Reports right; prints current table view. `[P]` Base it on reference's `@media print` blocks: visibility `hidden` vs colour reset.

---

**Purpose:** Shows only the reports the user has the right for; Superadmin/Admin see all 7 reports, User sees only Active Employees.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE                                                   [1] role    |
[2] theme    |
|                                                                            [2] theme    |
+--------------------------------------------------------------------------------+
|  [1] Product Master List                                                   [3] Search  |
|  [2] Active Employees                                                      [4] New ...  |
|  [3] All Employees                                                         |
|  [4] Employee Job History (employee picker)                               |
|  [5] Top Customers                                                         |
|  [6] Top Products                                                          |
|  [7] Top Sales                                                             |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Header breadcrumb and role badge.** **Required?** N/A. Reuses the built `PentadERP / WORKSPACE` breadcrumb and top-right role badge.
2. **Theme toggle.** **Required?** N/A. Reuses the built light/dark theme control.
3. **Module eyebrow/pill, "REPORTS MODULE".** **Required?** N/A.
4. **Page title and subtitle.** **Required?** N/A. "Reports". Subtitle: "Choose an authorized report. Use Print to print or save the report as PDF."
5. **Report picker area.** **Required?** N/A. Vertical list of report buttons; shown only for reports user has right for. Superadmin/Admin see all 7; User sees only Active Employees. Buttons use `report-picker-button` class, pill-shaped, `brand-600` text when active, `gray-200`/`dark:bg-slate-800/50` inactive. `[P]` Follows the report picker pattern from `static/reports.js`.
6. **No-report message.** **Required?** N/A. Shown when user has no report rights: "You do not have access to any individual reports. Ask an administrator to assign report rights."
7. **Print / Save as PDF button.** **Required?** N/A. Shown per Reports right; when clicked, prints `#reportPrintArea` or saves as PDF. `[P]` Per guide facts: 7 reports with date range + Top N, per-report rights, Print/Save as PDF.

---
## 10. No-Right Variants

**Scenario:** User without Reports right.

**Report Picker - No-Right Variant:**

```text
+--------------------------------------------------------------------------------+
| (No report access)                                                             |
|                                                                              |
| You do not have access to any individual reports. Ask an administrator to assign |
| report rights.                                                                 |
+--------------------------------------------------------------------------------+
```

**Report Output - No-Right Variant:**

```text
+--------------------------------------------------------------------------------+
| (No report access)                                                             |
|                                                                              |
| You do not have access to run reports. Contact Superadmin for report rights.   |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

- **No-right message.** **Required?** N/A. Shown when user has no Reports right; informational text only.
- **Print/Save as PDF button.** **Required?** N/A. Hidden when missing right; no form presented.

---
## 11. Gaps & Assumptions

- Report rights are configured per the 36-right matrix: Reports group has 7 rights (Top Customers, Product Master List, Top Products, Active Employees, All Employees, Employee Job History, Top Sales). `[P]` Per guide facts.
- The reference HTML Reports screen has only 2 report tabs with no filters or Top N; this wireframe adds date range, Top N, and ranking per guide Figure 28.
- Print stylesheet: base on reference's two `@media print` blocks (visibility `hidden` vs colour reset); recommend one. `[P]` Mark changes PROPOSED.
- Employee Job History salary hidden without View Job History right per Data Privacy Act RA 10173. `[P]`
- Top Customers rank + total sales per guide Figure 28; reference has no totals or ranking. `[P]`
- Audit log viewer Superadmin only; filters (user, event type, dates), table, pagination, empty state all `[P]` PROPOSED.
- Top N from 1 to 100; default 10. `[P]`
- Date range filters inclusive of start/end dates. `[P]`
- Print/Save as PDF buttons shown per individual report rights. `[P]`
- No row splits in printed tables; table header repeats per page. `[P]` Base on reference's print rules.
- Light theme forced in print; hide sidebar, tabs and buttons. `[P]` Per print stylesheet spec.
---
## 9. Superadmin-only Audit Log Viewer (PROPOSED)

**Purpose:** Superadmin can view audit log with filters for user, event type, and dates; table with pagination; empty state.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / AUDIT LOG VIEWER                     [1] Superadmin   |
+--------------------------------------------------------------------------------+
| +----------------------+ ---------+ -------------+ ------------+----------+ |
| | User                 | Event Type| Date            | Description   | Duration   | |
| | -------------------- | --------- | ------------- | ------------ | --------- | |
| | Admin                | LOGIN     | 2024-01-15 09:00| User login    | —          | |
| | Superadmin           | CREATE    | 2024-01-16 14:30| Created sale  | 2 min      | |
| | ...                                                             |           | |
| +----------------------+ ---------+ -------------+ ------------+----------+ |
|  Page 1 of 3   [First] [Prev] [1] [2] [3] [Next] [Last]                       |
+--------------------------------------------------------------------------------+
|                                0 entries.                                   |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Header breadcrumb and role badge.** **Required?** N/A. Shows Superadmin badge `amber-500/10` with `amber-500` text.
2. **Filter: User.** **Required?** N/A. Dropdown with all users; filters audit entries by user. `[P]` Per guide facts: audit viewer Superadmin only.
3. **Filter: Event Type.** **Required?** N/A. Dropdown with LOGIN, CREATE, EDIT, DELETE, RESTORED, etc. `[P]` Per guide facts: event types filter.
4. **Filter: Date Range.** **Required?** N/A. Start date and end date inputs `[P]` per guide facts: filters with dates.
5. **Table header row.** **Required?** N/A. Columns: User, Event Type, Date, Description, Duration. Uppercase bold on `gray-50`/`gray-100`.
6. **Table data rows.** **Required?** N/A. User name, event type text, datetime stamp, description text, duration (e.g., "2 min"). `[P]` Duration column proposed.
7. **Pagination.** **Required?** N/A. Page navigation: "Page 1 of 3 [First] [Prev] [1] [2] [3] [Next] [Last]". `[P]` Pagination proposed; reference does not have this for audit log.
8. **Empty state.** **Required?** N/A. Centered "No audit entries found." `p-6` when no entries match filters.
9. **Print / Save as PDF button.** **Required?** N/A. Shown per Reports right; prints audit log table.

**Role/state variants:**

- **Superadmin:** Full access to audit log viewer; all filters available; pagination controls visible.
- **Admin:** Can view audit log but some filters may be hidden; no pagination if single page.
- **User:** No access to audit log viewer; button hidden; "Coming soon" state if module not built.

---
## 8. Reports: Top Sales

**Purpose:** Top N largest transactions in a date range; requires date range + Top N inputs. Shows auto-numbered read-only Trans No, dropdowns from active customers/employees.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / TOP SALES                                          |
+--------------------------------------------------------------------------------+
| +----------------------+ ---------+ ---------+ -------------+ ---------+ |
| | Transaction No       | Sale Date | Customer    | Salesperson   | Sales Total | |
| | -------------------- | --------- | --------- | ------------- | --------- | |
| | T-001                | 2024-03-15| Acme Corp   | Juan Dela Cruz| $1,250.00 | |
| | T-002                | 2024-03-10| Banco Inc   | Maria Santos  | $800.00   | |
| | ...                                                             |           | |
| +----------------------+ ---------+ ---------+ -------------+ ---------+ |
|                    From: 2024-01-01   To: 2024-12-31   Top N: 10                         |
+--------------------------------------------------------------------------------+
|                                3 row(s).                                      |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Header breadcrumb and title.** **Required?** N/A. "Top Sales".
2. **Filter area: Start Date.** **Required?** N/A. Date input; pre-filled with `config.today.slice(0, 7) + "-1"`.
3. **Filter area: End Date.** **Required?** N/A. Date input; pre-filled with `config.today`.
4. **Filter area: Top N.** **Required?** N/A. Number input `min=1`, `max=100`, `step=1`, required; pre-filled with `10`.
5. **Table header row.** **Required?** N/A. Columns: Transaction No, Sale Date, Customer, Salesperson, Sales Total. Uppercase bold on `gray-50`/`gray-100`. Transaction No read-only `[P]` auto-numbered read-only.
6. **Table data rows.** **Required?** N/A. Transaction No read-only/disabled, sale date, customer name (dropdown from active customers), salesperson name (dropdown from active employees), sales total formatted as currency PHP. `[a sale line uses the price on the SALE DATE]`.
7. **Empty state.** **Required?** N/A. Centered "No records found." `p-6` when no sales match the date range.
8. **Print / Save as PDF button.** **Required?** N/A.

---
## 7. Reports: Top Products

**Purpose:** Top N products by quantity and amount in a date range; requires date range + Top N inputs.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / TOP PRODUCTS                                       |
+--------------------------------------------------------------------------------+
| +----------------------+ ---------+ ---------+ ---------+ ---------+ |
| | Product Code         | Product   | Quantity Sold | Sales Total | Rank   | |
| | -------------------- | --------- | ------------- | ----------- | ------ | |
| | P-001                | Product A | 15            | $180.00     | 1      | |
| | P-002                | Product B | 10            | $150.00     | 2      | |
| | ...                                                             |           | |
| +----------------------+ ---------+ ---------+ ---------+ ---------+ |
|                    From: 2024-01-01   To: 2024-12-31   Top N: 10                         |
+--------------------------------------------------------------------------------+
|                                3 row(s).                                      |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:** (same structure as Top Customers, columns adapted for products)

1. **Header breadcrumb and title.** **Required?** N/A. "Top Products".
2. **Filter area: Start Date.** **Required?** N/A. Date input; pre-filled with `config.today.slice(0, 7) + "-1"`.
3. **Filter area: End Date.** **Required?** N/A. Date input; pre-filled with `config.today`.
4. **Filter area: Top N.** **Required?** N/A. Number input `min=1`, `max=100`, `step=1`, required; pre-filled with `10`.
5. **Table header row.** **Required?** N/A. Columns: Product Code, Product, Quantity Sold, Sales Total, Rank. Uppercase bold on `gray-50`/`gray-100`. `[P]` Rank column `[P]` per guide pattern.
6. **Table data rows.** **Required?** N/A. Product Code bold, product description, quantity sold, sales total formatted as currency PHP, rank number.
7. **Empty state.** **Required?** N/A. Centered "No records found." `p-6` when no products match.
8. **Print / Save as PDF button.** **Required?** N/A.

---
## 6. Reports: Top Customers

**Purpose:** Top N customers by total sales in a date range; requires date range + Top N inputs.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / TOP CUSTOMERS                                      |
+--------------------------------------------------------------------------------+
| +----------------------+ ---------+ ---------+ ---------+ ---------+ |
| | Customer No          | Customer  | Transactions | Sales Total | Rank   | |
| | -------------------- | --------- | ------------ | ----------- | ------ | |
| | C-001                | Acme Corp | 12           | $12,500.00  | 1      | |
| | C-002                | Banco Inc | 8            | $9,800.00   | 2      | |
| | ...                                                             |           | |
| +----------------------+ ---------+ ---------+ ---------+ ---------+ |
|                    From: 2024-01-01   To: 2024-12-31   Top N: 10                         |
+--------------------------------------------------------------------------------+
|                                3 row(s).                                      |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Header breadcrumb and title.** **Required?** N/A. "Top Customers".
2. **Filter area: Start Date.** **Required?** N/A. Date input `py-2.5`, `rounded-xl`, `bg-white`/`dark:bg-slate-950/50`, border `gray-200`/`dark:bg-slate-800/50`. `[P]` Follows the date field pattern from `static/reports.js`. Pre-filled with `config.today.slice(0, 7) + "-01"`.
3. **Filter area: End Date.** **Required?** N/A. Date input; pre-filled with `config.today`. `[P]` Same pattern.
4. **Filter area: Top N.** **Required?** N/A. Number input `min=1`, `max=100`, `step=1`, required; pre-filled with `10`. `[P]` Same pattern.
5. **Table header row.** **Required?** N/A. Columns: Customer No, Customer, Transactions, Sales Total, Rank. Uppercase bold on `gray-50`/`gray-100`. `[P]` Rank column `[P]` per guide facts: Figure 28 shows rank + total sales; reference has no totals or ranking.
6. **Table data rows.** **Required?** N/A. Customer No bold, customer name, transaction count, sales total formatted as currency, rank number.
7. **Empty state.** **Required?** N/A. Centered "No records found." `p-6` when no customers match the date range.
8. **Print / Save as PDF button.** **Required?** N/A. Shown per Reports right.

*Note: The reference HTML Reports screen has only 2 report tabs and no filters or Top N. Guide Figure 28 shows Top Customers with rank + total sales. This wireframe adds the date range, Top N, and ranking per the guide.*

---
## 5. Reports: Employee Job History

**Purpose:** List job history for a selected employee; salary shown only if user has View Job History right. Per Data Privacy Act RA 10173, salary and job history hidden without that right.

**Layout - With View Job History right:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / EMPLOYEE JOB HISTORY                               |
+--------------------------------------------------------------------------------+
| [Employee picker]                                                                |
| +----------------------------------------------------------+ -------------+ |
| | Effective Date | Job Code | Job        | Dept Code | Department | Salary | |
| | -------------- | -------- | --------- | --------- | --------- | ------ | |
| | 2020-03-01     | J-001    | Mgr       | D-001     | Sales     | $5,000 | |
| | 2021-06-15     | J-002    | Asst      | D-002     | HR        | $4,500 | |
| | ...                                                             |           | |
| +----------------------------------------------------------+ -------------+ |
|                                                              0 row(s).                                      |
+--------------------------------------------------------------------------------+
```

**Layout - Without View Job History right (salary hidden):**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / EMPLOYEE JOB HISTORY (salary masked)              |
+--------------------------------------------------------------------------------+
| [Employee picker]                                                                |
| +----------------------------------------------------------+ ---------+ |
| | Effective Date | Job Code | Job        | Dept Code | Department |     | |
| | -------------- | -------- | --------- | --------- | --------- | ---- | |
| | 2020-03-01     | J-001    | Mgr       | D-001     | Sales     | —      | |
| | ...                                                             |           | |
| +----------------------------------------------------------+ ---------+ |
|                                                              0 row(s).                                      |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Employee picker.** **Required?** N/A. Dropdown of active employees; populated from `/api/employees/options`. `[P]` Employee options from active employees only. `[P]` Shown only when user has View Job History right or when employee is selected.
2. **Table header row.** **Required?** N/A. Columns: Effective Date, Job Code, Job, Dept Code, Department, Salary. Uppercase bold on `gray-50`/`gray-100`. `[P]` Salary column hidden without View Job History right; shows `—` instead.
3. **Table data rows - With right.** **Required?** N/A. All columns including salary formatted as currency PHP.
4. **Table data rows - Without right.** **Required?** N/A. Salary column shows `—`; Job Code, Job, Dept Code, Department visible.
5. **Empty state.** **Required?** N/A. Centered "No records found." `p-6` when no job history available.
6. **Print / Save as PDF button.** **Required?** N/A. Shown per Reports right.

---
## 4. Reports: All Employees

**Purpose:** List all employees including separated; read-only. Includes Separation Date, Status, Stamp columns. Admin/Superadmin see Status and Stamp; User sees active only.

**Layout - Admin/Superadmin:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / ALL EMPLOYEES                                      |
+--------------------------------------------------------------------------------+
| +----------------------------------------------------------+ ---------+ ----+ |
| | Employee No | Employee       | Gender | Hire Date   | Status   | Stamp   | |
| | ----------- | -------------- | ------ | ----------- | -------- | ------- | |
| | E-001       | Maria Santos   | F      | 2020-03-15  | Active   | CREATED by John @ 2024-01-15 10:30| |
| | E-002       | Juan Dela Cruz   | M      | 2021-01-10  | Inactive | DELETED by Jane @ 2024-02-20 14:15| |
| | ...                                                             |           | |
| +----------------------------------------------------------+ ---------+ ----+ |
|                                15 row(s).                                     |
+--------------------------------------------------------------------------------+
```

**Layout - User (active only):**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / ALL EMPLOYEES (active only)                       |
+--------------------------------------------------------------------------------+
| +----------------------------------------------------------+ ---------+ |
| | Employee No | Employee       | Gender | Hire Date     |           | |
| | ----------- | -------------- | ------ | ------------- | --------- | |
| | E-001       | Maria Santos   | F      | 2020-03-15    |           | |
| | ...                                                             |           | |
| +----------------------------------------------------------+ ---------+ |
|                                3 row(s).                                      |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Header breadcrumb and title.** **Required?** N/A. "All Employees".
2. **Table header row.** **Required?** N/A. Columns: Employee No, Employee, Gender, Hire Date, Status, Stamp. Uppercase bold on `gray-50`/`gray-100`. `[P]` Status and Stamp columns per role config.
3. **Table data rows - Admin/Superadmin.** **Required?** N/A. All columns including Status badge and Stamp text `CREATED/EDITED/DELETED/RESTORED + user + datetime`. Stamp shaded bg `bg-gray-100`/`dark:bg-slate-950/50` when DELETED/RESTORED.
4. **Table data rows - User.** **Required?** N/A. Active rows only; Status and Stamp hidden; shows `—` for Stamp column.
5. **Empty state.** **Required?** N/A. Centered "No records found." `p-6` when no employees available.
6. **Print / Save as PDF button.** **Required?** N/A. Shown per Reports right.

---
## 3. Reports: Active Employees

**Purpose:** List employees who are currently active (not separated); read-only, no filters.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / REPORTS MODULE / ACTIVE EMPLOYEES                                  |
+--------------------------------------------------------------------------------+
| +----------------------------------------------------------+ -------------+ |
| | Employee No | Employee       | Gender | Hire Date      | Job     | Dept | |
| | ----------- | -------------- | ------ | ------------- | ------ | ---- | |
| | E-001       | Maria Santos   | F      | 2020-03-15    | Mgr    | Sales| |
| | E-002       | Juan Dela Cruz   | M      | 2021-01-10    | Asst   | HR   | |
| | ...                                                             |               | |
| +----------------------------------------------------------+ -------------+ |
|                                0 row(s).                                      |
+--------------------------------------------------------------------------------+
```

**Numbered annotations:**

1. **Header breadcrumb and title.** **Required?** N/A. "Active Employees".
2. **Table header row.** **Required?** N/A. Columns: Employee No, Employee, Gender, Hire Date, Job, Dept. Uppercase bold on `gray-50`/`gray-100`.
3. **Table data rows.** **Required?** N/A. Employee No bold, fullName, gender (M/F), hireDate, job, department. `[N]` Separation date column not shown (active rows only).
4. **Empty state.** **Required?** N/A. Centered "No records found." `p-6` when no active employees.
5. **Print / Save as PDF button.** **Required?** N/A. Shown per Reports right.

---