# S3-UIX-02 — Employee Profile Wireframes

Low-fidelity, grayscale structure-only wireframes based on `PentadERP_index (FINAL).html` and its inline employee handlers. The existing dialogs follow the shared design system's centered `max-w-md` modal, `p-8` spacing, stacked fields, uppercase 10px labels, and rounded input/button treatment. No colors are shown below.

**Notation:** `[P]` marks an element or behavior that is **PROPOSED (not in reference)**. `Required?` indicates field requirement; it is N/A for non-fields.
## 1. Employee List / Table
## 2. Employee Form (Add/Edit)
## 3. Employee Profile (Timeline)
## 4. Job History Add/Edit/Delete
## 5. Search and Filters (PROPOSED)
## 6. Soft Delete / Restore
## 7. No-Right Variants
## Gaps & Assumptions

- The expected `Private-Design-Reference` folder was unavailable. The exact-named HTML was available at `reference_html/PentadERP_index (FINAL).html` and was inspected read-only.
- Source modal IDs: `#empModal` (employee add/edit form), `#jhFormModal` (job history add/edit form). These follow the design-system modal pattern (` .modal-overlay`, `max-w-md`, `rounded-3xl`, `p-8`).
- 36 rights: Customer 3; Product 6 (incl. prices); HR 13 (incl. View/Add/Edit/Delete Job History); Sales 7 (incl. Sale Detail); Reports 7. Right-gated visibility follows the rights matrix per module.
- Active/Inactive/All tabs: only Admin/Superadmin see all three with count chips; Users see active-only with no tabs (per guide facts: "User sees active rows only: no Active/Inactive/All tabs, no Status or Stamp columns").
- Delete = soft delete with confirm; Restore on deleted rows (shaded).
- Employee: separation date (left the company) is different from deleted; salary and job history hidden without View Job History right (Data Privacy Act RA 10173).
- Birth date and Hire date: hire date must be after birth date and not in the future.
- Salary: hidden without View Job History right per Data Privacy Act.
- Timeline placeholder: PROPOSED (not in reference) — visual design to be determined in later sprint.
- Duplicate effective-date error: PROPOSED (not in reference) — inline validation error for job history effective date overlap.

**Purpose:** Action buttons hidden when the user lacks the matching right.

**Behavior:**

- **History button:** Hidden on employee profile without View Job History right.
- **Edit button:** Hidden when user lacks Edit right for the employee record.
- **Delete button:** Hidden when user lacks Delete right; shows "Coming soon" grayed-out pill instead.
- **Restore button:** Hidden on non-deleted rows; not applicable for User role.

**Visual:** Buttons simply absent from the action column. No placeholder or broken icon shown.

**Purpose:** Soft delete employee record with confirmation; restore deleted records.

**Behavior:**

- **Delete:** Employee list row → Delete button → Confirm modal (`.confirm-dialog` class: `max-w-md`, `rounded-3xl`, `p-7`; amber icon/title area with red Proceed action and neutral Cancel) → "Are you sure you want to delete this employee?" → Soft delete: row shaded (bg-gray-100/50 dark:bg-slate-950/50), Status changed to "Deleted", Stamp updated to "DELETED by user on datetime", Delete button replaced by Restore button.
- **Restore:** Deleted row → Restore button → Same confirm modal → Row restored, Status changed to "Active" or previous status, Stamp updated to "RESTORED by user on datetime", Restore button replaced by Delete button.
- **Role restrictions:** Users cannot delete; Admin/Superadmin can delete per rights. Only Superadmin can restore permanently deleted records (if applicable).

**Navigation:** Delete → confirm modal → soft delete; Restore → confirm modal → restore row.

**Purpose:** Type-ahead filter on employee list table.

**Layout:**

```text
+-----------------------------+
| [Search]    [Add Employee]  |
|                             |
|   [Magnifying glass icon]   |
|   sr-only: "Search employees"|
+-----------------------------+
```

**Behavior:** As user types, filters emp no, name, gender, birth, hire, sep date in real-time. No separate filter tabs for active/inactive/all on User view; Admin/Superadmin see the tabs.

**Purpose:** Add, edit, or delete job history entries for an employee (effective date, job, department, salary).

**Layout (Add/Edit Dialog):**

```text
+--------------------------------------+
| [1] Add Job History      [2] Close   |
|                                      |
| [3] Effective Date               [4] Emp No     |
|     +----------------+     +-----------+  |
|     |              |     |           |  |
| [5] Job Title                     |
|     +-----------+     +-----------+  |
|     |           |     |           |  |
| [6] Department                    |
|     +-----------+     +-----------+  |
|     |           |     |           |  |
| [7] Salary                                  |
|     +-------------------------------+  |
|     |                               |  |
|                                       |  |
+--------------------------------------+
```

**Numbered annotations:**

1. Dialog title. **Required?** N/A. Reference changes between "Add Job History" and "Edit Job History".
2. Close icon/button. **Required?** N/A. Closes dialog without saving.
3. Emp No, type `text`. **Required?** Display only; auto-populated from employee record.
4. Emp No display. **Required?** N/A. Shows employee number.
5. Job Title, type `text`. **Required?** Yes. Uppercase 10px label, rounded-xl input.
6. Department, type `select`. **Required?** Yes. Uppercase 10px label, rounded-xl select. Options populated from departments list.
7. Salary, type `number`. **Required?** Yes, if user has View Job History right. Uppercase 10px label, rounded-xl input. **PROPOSED**: Hidden without View Job History right (Data Privacy Act RA 10173).

**Duplicate effective-date error:** **PROPOSED (not in reference):** Inline error message if effective date overlaps with existing job history entry. Displayed below the Effective Date field using `form-message` class: `border-red-500/25`/`dark:bg-red-600/08`, `color-red-500`/`dark:text-rose-500`, `text-sm` font. Applied dynamically via JavaScript on blur or submit.

**Role/rights visibility:**

- **Superadmin:** All fields visible; can add/edit/delete any job history entry.
- **Admin:** All fields visible if View Job History right present; salary visible. Cannot edit Superadmin employee records.
- **User:** Job History fields hidden without View Job History right. Salary hidden. Cannot add/edit job history entries.

**Delete:** **PROPOSED:** Delete button on job history entry shows confirm modal with "Are you sure?" text. Soft delete with shaded row restoration. "Cannot delete, used by payroll" message if entry is referenced by payroll records.

**Navigation:** Save → saves fields, closes dialog, rerenders profile, shows success toast; Cancel → closes without saving; Delete → opens confirm modal.

**Purpose:** Display detailed employee profile with timeline of employment history, job changes, and stamps.

**Layout:**

```text
+--------------------------------------+
| Employee Profile: [Emp No] [Name]    |
|                                      |
| [Timeline Placeholder]               |
|                                      |
| +----------------------------------+ |
| | Employment Timeline              | |
| |----------------------------------| | |
| | [Date Range] [Job Title]         | | |
| | [Department]                     | | |
| | [Salary]                         | | |
| | [Stamp: CREATED by user on date] | | |
| |----------------------------------| | |
| | ... (more entries)               | | |
| +----------------------------------+ |
|                                      |
| [Job History] button                 |
| (opens job history add/edit/delete)  |
|                                      |
| Stamp History:                       |
| CREATED by Sarah Chen on 2024-01-15  |
| EDITED by Juan Dela Cruz on 2024-03-20 |
| DELETED by Admin on 2024-06-10 (shaded) |
| RESTORED by Superadmin on 2024-07-01 (shaded) |
+--------------------------------------+
```

**Numbered annotations:**

1. Employee profile heading. **Required?** N/A. Shows emp no and name.
2. Timeline placeholder. **PROPOSED (not in reference):** Visual timeline of employment history. Placeholder indicates where timeline will be rendered.
3. Employment timeline entries. **PROPOSED:** Each entry shows date range, job title, department, salary, and stamp.
4. Job History button. **Required?** N/A. Opens `#jhFormModal` for job history add/edit/delete.
5. Stamp History. **Required?** Superadmin/Admin only. Lists all CREATED/EDITED/DELETED/RESTORED events with user and datetime. Users see "—" placeholder only.

**Role/rights visibility:**

- **Superadmin:** Full profile with all timeline entries, salary visible, all stamp history visible, Job History button enabled.
- **Admin:** Profile with most timeline entries; salary visible if View Job History right present; restricted stamp history.
- **User:** Profile WITHOUT View Job History right → salary hidden, job history section collapsed/empty, stamp history shows "—" placeholder. No Job History button.

**Navigation:** Job History button → opens `#jhFormModal` for add/edit/delete job history entries.

**Purpose:** Create a new employee record or update an existing employee profile.

**Layout:**

```text
+--------------------------------------+
| [1] Add Employee Account      [2] Close |
|                                      |
| [3] Emp No                   [4] Emp No     |
|     +----------------+     +-----------+  |
|     |              |     |           |  |
| [5] First Name            [6] Last Name     |
|     +-----------+     +-----------+  |
|     |           |     |           |  |
| [7] Email                             |
|     +----------------------------+   |
|     |                            |   |
| [8] Gender                            |
|     +-----------+     +-----------+  |
|     |           |     |           |  |
| [9] Birth Date              [10] Hire Date    |
|     +-----------+     +-----------+  |
|     |           |     |           |  |
| [11] Sep. Date                              |
|     +-------------------------------+  |
|     |                               |  |
+--------------------------------------+
```

**Numbered annotations:**

1. Dialog title. **Required?** N/A. Reference changes between "Add Employee Account" and "Edit Employee Account".
2. Close icon/button. **Required?** N/A. Closes dialog without saving.
3. Emp No, type `text`. **Required?** Yes, on add; read-only on edit. Auto-generated on add.
4. Emp No display, type `text`. **Required?** N/A. Display only on view mode.
5. First Name, type `text`. **Required?** Yes. Uppercase 10px label, rounded-xl input.
6. Last Name, type `text`. **Required?** Yes. Uppercase 10px label, rounded-xl input.
7. Email, type `email`. **Required?** Yes. Editable on add; read-only on edit. Uppercase 10px label.
8. Gender, type `select`. **Required?** Yes. Options: Male, Female. Uppercase 10px label, rounded-xl select.
9. Birth Date, type `date`. **Required?** Yes. Uppercase 10px label, rounded-xl input. Must not be in the future.
10. Hire Date, type `date`. **Required?** Yes. Uppercase 10px label, rounded-xl input. Must be after birth date and not in the future.
11. Sep. Date, type `date`. **Required?** N/A (optional). Uppercase 10px label, rounded-xl input. **PROPOSED**: sep date optional, not before hire date. If employee is currently employed, field is empty.

**Role/rights visibility:**

- **Superadmin:** All fields visible; can create/manage any employee record.
- **Admin:** All fields visible; can edit employee records per role restrictions.
- **User:** Sep. Date field hidden without View Job History right (Data Privacy Act RA 10173). Salary and job history hidden without View Job History right.

**Navigation:** Save → saves fields, closes dialog, rerenders list, shows success toast; Cancel → closes without saving.

**Purpose:** Display employee records with search, filters, and action columns. Superadmin/Admin see all rows with status/stamp columns; Users see active-only with no Status/Stamp columns.

**Layout:**

```text
+---------------------------------------------------------------+
| [Search]    [Add Employee]                                    |
|                                                                 |
| +----------------------------+----------------------------+  |
| | Emp No | Name               | Gender | Birth      | Hire     |  |
| |--------+--------------------+--------+------------+----------|  |
| | E001   | Juan Dela Cruz       | Male   | 1990-03-15 | 2018-06-01|  |
| |--------+--------------------+--------+------------+----------|  |
| | E002   | Maria Santos         | Female | 1985-07-22 | 2020-01-15|  |
| |--------+--------------------+--------+------------+----------|  |
| | E003   | Pedro Reyes          | Male   | 1992-11-30 | 2019-09-10|  |
| +----------------------------+----------------------------+  |
|                                                                 |
|  Active  Inactive  All                                          |
+---------------------------------------------------------------+
```

**Numbered annotations:**

1. **Search field.** **Required?** N/A. Type-ahead filter on emp no/name; magnifying glass icon with sr-only label "Search employees". Resides inside `.record-toolbar` flex container.
2. **Add Employee button.** **Required?** N/A. Primary pill button opens add employee dialog; hidden when user lacks Create right for Employees module.
3. **Emp No column.** **Required?** Yes. Employee number; bold, read-only.
4. **Name column.** **Required?** Yes. Full name of employee.
5. **Gender column.** **Required?** Yes. Male/Female; small pill badge.
6. **Birth column.** **Required?** Yes. Birth date (YYYY-MM-DD format).
7. **Hire column.** **Required?** Yes. Hire date (YYYY-MM-DD format).
8. **Sep. Date column.** **Required?** Conditional. Separation date if employee left the company; empty if currently employed. **PROPOSED**: sep date optional, not before hire date.
9. **Status column.** **Required?** Superadmin/Admin only. Status badge indicating active/pending/blocked. **PROPOSED**: Users see active rows only; no Active/Inactive/All tabs, no Status or Stamp columns.
10. **Stamp column.** **Required?** Superadmin/Admin only. Stamp showing CREATED/EDITED/DELETED/RESTORED + user + datetime. **PROPOSED**: Users see "—" placeholder only.
11. **Actions column.** **Required?** Right-aligned. Contains History, Edit, Delete, and Restore (for deleted rows) buttons. Buttons hidden when matching right is absent (no-right variant).

**Role/state:**

- **Superadmin:** See all rows with Active/Inactive/All tabs + count chips. See Status and Stamp columns. All action buttons visible per rights.
- **Admin:** See all rows with Active/Inactive/All tabs + count chips. See Status and Stamp columns. Action buttons visible per rights (no-delete for User role, etc.).
- **User:** See active rows only with no tabs, no Status or Stamp columns. No count pills. Action buttons: History, Edit only; Delete hidden. Restore not applicable.

**Navigation:** Search → filter results; Add Employee → opens dialog; History → opens employee profile; Edit → opens add/edit dialog; Delete → confirm soft-delete modal; Restore → restores deleted employee.