# S3-UIX-01 — HR Department & Job Wireframes

Low-fidelity, grayscale structure-only wireframes based on `PentadERP_index (FINAL).html` and its inline HR handlers. The existing dialogs follow the shared design system's centered `max-w-md` modal, `p-8` spacing, stacked fields, uppercase 10px labels, and rounded input/button treatment. No colors are shown below.

**Notation:** `[P]` marks an element or behavior that is **PROPOSED (not in reference)**. `Required?` indicates field requirement; it is N/A for non-fields.

## 1. HR Tab Bar

**Purpose:** Primary navigation for HR module, providing access to Employees, Jobs, and Departments sections.

**Layout:**

```text
+--------------------------------------+
| [Employees] [Jobs] [Departments]     |
|                                      |
| Main content area (varies by selection)|
+--------------------------------------+
```

**Numbered annotations:**

1. **Employees tab.** **Required?** N/A. Selects Employees list view; shows all employee records with action columns.
2. **Jobs tab.** **Required?** N/A. Selects Jobs list view; shows job positions with department assignments.
3. **Departments tab.** **Required?** N/A. Selects Departments list view; shows organizational units with employee counts.
4. **Active/Inactive/All tabs.** **Required?** N/A. **PROPOSED:** toggles visibility of active/inactive/archived records; only Admin/Superadmin see all three tabs; Users see active-only.

**Navigation:** Tab selection → corresponding list screen; Close → dismiss HR module.

**Role/state:** Superadmin/Admin see all three tabs + count chips; Users see only Active tab with no count pills for Inactive/All.
## 2. Department List

**Purpose:** Display organizational departments with search, filtering, and action columns.

**Layout:**

```text
+--------------------------------------+
| [Search]    [Add Department]         |
|                                      |
| +----------------------------+--------+
| | Department Name            | Actions |
| | ---------------------------- |---------|
| | Engineering                | Edit Del  |
| | ---------------------------- |---------|
| | Marketing                  | Edit Del  |
| | ---------------------------- |---------|
| | Finance                    | Edit Del  |
| +----------------------------+--------+
|                                      |
| Active  Inactive  All                |
+--------------------------------------+
```

**Numbered annotations:**

1. **Search field.** **Required?** N/A. Type-ahead filter on department name; magnifying glass icon with sr-only label "Search departments".
2. **Add Department button.** **Required?** N/A. **PROPOSED:** primary pill button (`btn-primary`) opens add department dialog; hidden when user lacks Create right for Departments module.
3. **Department Name column.** **Required?** N/A. Department organizational name; truncated with ellipsis if overflow.
4. **Actions column.** **Required?** N/A. Right-aligned Edit/Delete buttons per user rights; hidden when matching right is absent (no-right variant).
5. **Active/Inactive/All tabs.** **Required?** Admin/Superadmin only. Toggle row visibility; count chips show total per status. **PROPOSED:** Users see Active-only with no tabs.

**Navigation:** Search → filter results; Add Department → opens dialog; Edit → opens add/edit dialog with read-only code; Delete → confirm modal with soft-delete; Restore → restores deleted department.

**Role/state:** Superadmin/Admin see all rows + Active/Inactive/All tabs + count chips; Users see active rows only with no tabs, no Status/Stamp columns. No-right variants hide Edit/Delete buttons.
## 3. Job List
## 4. Add/Edit Dialog (Department/Job)
## 5. Search and Active/Inactive/All Tabs
## 6. Deleted View with Restore
## 7. "Cannot delete, used by job history" Message
## 8. No-Right Variants
## Gaps & Assumptions

- The reference renders HR module via `renderHR` handler; existing page built if it exists, else designed from reference + guide facts.
- Source: `reference renderHR`, `openSimple`, `#simpleModal` — these open the add/edit dialog modals per design-system patterns.
- Active/Inactive/All tabs: only Admin/Superadmin see all three with count chips; Users see active-only with no tabs (per guide facts: "User sees active rows only: no Active/Inactive/All tabs, no Status or Stamp columns").
- 36 rights: Customer 3, Product 6 (incl. prices), HR 13 (incl. View/Add/Edit/Delete Job History), Sales 7 (incl. Sale Detail), Reports 7. Right-gated visibility follows the rights matrix per module.
- Delete = soft delete with confirm; Restore on deleted rows (shaded). Delete confirmation modal with "Are you sure?" text.
- "cannot delete, used by job history" message: dynamic message with job reference count; only Superadmin can override.
- Edit dialog: code read-only on edit; input fields disabled with grayed appearance.
- No-right variants: buttons hidden when matching right is absent; design uses `is-admin` flag + module-specific rights config from rights matrix.
- All new components follow existing design-system tokens: DM Sans, remapped Tailwind palette (`brand`=emerald, `indigo`=terracotta, `sky`=warm orange, `slate`=warm stone/charcoal), paired light/dark treatments using `.dark` class, consistent spacing/radii (rounded-xl for inputs, rounded-full for pills/badges, p-6/p-7/p-8 padding rhythm).
- Screens not yet built: write "not built yet" and mark as PROPOSED (not in reference).
- Dialog modals follow `.modal-overlay` pattern: `max-w-md`, `rounded-3xl`, `p-8`, charcoal overlay with 4px backdrop blur, z-index 200.
- Search pills: `rounded-full` border-radius, `gray-200`/`dark:bg-slate-800/50` background, `brand-600` focus ring.
- Tab pills: `gap-0.35rem`, `padding 0.45rem 0.8rem`, `font-size 0.68rem`, `font-weight 800`; active = solid `brand-600` with white text; inactive = `gray-200`/`dark:bg-slate-800/10` with muted text.
- Status badges: Active `emerald-500/10`/ `emerald-500`, Inactive `slate-600/10`/ `slate-400`, Pending `amber-500/10`/ `amber-500`, Blocked `red-500/10`/ `red-500`.
- Stamp text: `—` when no value; Admin/Superadmin show `CREATED/EDITED/DELETED/RESTORED + user + datetime`; Users see `—` only.
- Edit/Delete/Restore buttons: Edit = `btn-outline`/`brand-600`, Delete = `btn-danger`/white, Restore = proposed `brand-600`/white on shaded background.
- Invalid-input style: `border-red-500`/`dark:border-red-600` with `focus:ring-red-500`/`dark focus:ring-red-600`; `form-message` error below field.
- Confirm/blocked-delete dialog: `.confirm-dialog` modal with amber title/red Proceed, neutral Cancel.
- "Coming soon" state: grayed-out pill button `opacity-50`/`dark:opacity-50` with `not-allowed` cursor; `coming-soon` caption.
- All visual/markup changes limited to HTML/template/CSS; no .py files, SQL, migrations, form actions/field names/ids, CSRF tokens, routes, or permission logic modified.

**Purpose:** UI behavior when user lacks required module rights.

**Scenarios:**

- **No Add right:** Add button (`btn-primary`) hidden from toolbar; no Add Department/Job dialog accessible; "Coming soon" state pill if module not yet built.
- **No Edit right:** Edit buttons in list rows hidden; Edit dialog not accessible from list; view-only mode for department/job details.
- **No Delete right:** Delete buttons hidden from action columns; soft-delete not available; "cannot delete" message not applicable (delete option absent).
- **No Restore right:** Restore button hidden from deleted view; deleted records remain shaded without Restore option.
- **No View right:** Department/Job list not accessible from HR tab bar; module pill hidden or grayed-out; "Coming soon" placeholder for missing modules.

**Role/state:** Each right (36 total: Customer 3, Product 6, HR 13, Sales 7, Reports 7) gates respective UI elements. UI shows/hides elements conditionally based on `is_admin` flag and module-specific rights from rights matrix. No-right variants result in hidden buttons, disabled actions, and "Coming soon" placeholder for missing modules.

**Navigation:** N/A — behavior is conditional hiding/showing of existing elements.

**Role/state:** Per the 36 rights distribution: Users have view-only access; Admin has full add/edit/delete/restore; Superadmin has all rights plus user management. Rights are checked at render time via `is-admin` flag and module-specific config from rights matrix.

**Purpose:** Inform user when delete operation cannot complete because record is referenced by job history.

**Layout (confirm modal):**

```text
+--------------------------------------+
| [1] Close                          |
| [2] Proceed                        |
|                                      |
| This department is used by job      |
| history and cannot be deleted.      |
| Remove the job references first,    |
| or contact Superadmin to restore.   |
|                                      |
|                                      |
+--------------------------------------+
```

**Numbered annotations:**

1. **Close button.** **Required?** N/A. Closes confirm modal without action.
2. **Proceed button.** **Required?** N/A. **PROPOSED:** disabled/removed when record is in use; shows explanatory message only.
3. **Explanatory message.** **Required?** N/A. Static text: "This department is used by job history and cannot be deleted. Remove the job references first, or contact Superadmin to restore."
4. **Job reference count.** **PROPOSED (not in reference):** "X active job(s) reference this department." Dynamic count of referencing job records.

**Navigation:** Close → dismiss modal; Proceed → **PROPOSED:** disabled when record in use; shows message only.

**Role/state:** Superadmin/Admin see message when delete is attempted on referenced record; Users do not see delete option for referenced records (rights-gated).

**Purpose:** Show deleted departments/jobs with Restore option.

**Layout:**

```text
+--------------------------------------+
| [Search]                            |
|                                      |
| +----------------------------+--------+
| | Department Name            | Actions |
| | ---------------------------- |---------|
| | Engineering (Deleted)      | Restore  |
| | ---------------------------- |---------|
| | Marketing (Deleted)        | Restore  |
| +----------------------------+--------+
|                                      |
| (No active records)                  |
+--------------------------------------+
```

**Numbered annotations:**

1. **Search field.** **Required?** N/A. Filter on deleted records' names.
2. **Department/Job Name column.** **Required?** N/A. Shows name with "(Deleted)" suffix and shading.
3. **Actions column.** **Required?** N/A. Restore button only (no Delete for already-deleted records); right-aligned; hidden when user lacks Restore right.
4. **"No active records" message.** **Required?** N/A. Shown when no deleted records exist; info text "No deleted departments found."

**Navigation:** Restore → restores record to Active status; closes deleted view; Search → filters deleted records.

**Role/state:** Superadmin/Admin see deleted rows with Restore button; Users do not see deleted rows (filtered out by rights). No-right variants hide Restore button.

**Purpose:** Filter and segment records in department/job lists.

**Layout (in list toolbar):**

```text
+--------------------------------------+
| [Search]    [Active] [Inactive] [All]|
|                                      |
| Records found: X                     |
+--------------------------------------+
```

**Numbered annotations:**

1. **Search field.** **Required?** N/A. Type-ahead filter; persists across tab selections; cleared on new search.
2. **Active tab.** **Required?** Users-only. **PROPOSED:** Admin/Superadmin see all three tabs; Users see only Active tab (hidden when missing). Active tab has count pill showing active record total.
3. **Inactive tab.** **Required?** Admin/Superadmin only. **PROPOSED:** hidden when user is not Admin/Superadmin; shows count of inactive records.
4. **All tab.** **Required?** Admin/Superadmin only. **PROPOSED:** hidden when user is not Admin/Superadmin; shows total record count including active/inactive.
5. **Records found count.** **Required?** N/A. Dynamic count updated by search and tab selection.

**Navigation:** Tab selection → filters records; Search → applies filter; Active/Inactive/All → toggles visibility.

**Role/state:** Superadmin/Admin see all three tabs with count chips (`Active: 24`, `Inactive: 5`, `All: 29`); Users see only Active tab with no count pills and no tab labels visible.

**Purpose:** Add new department or job position, or edit existing record.

**Layout (Add):**

```text
+--------------------------------------+
| [1] Close                          |
| [2] Save Department/Job              |
|                                      |
| [3] Code (read-only on edit)       [4] |
| | dept-001                         |  ⏹     |
| |                                    |        |
| [5] Department Name / Job Title      |
| |                                    |        |
| [6] Active                           |
| |                                    |        |
| [7] Inactive                         |
| +--------------------------------------+
```

**Layout (Edit - code read-only):**

```text
+--------------------------------------+
| [1] Close                          |
| [2] Save Changes                     |
|                                      |
| [3] Code: dept-001  **READ-ONLY**  [4] |
| | dept-001                         |  ⏹     |
| |                                    |        |
| [5] Department Name / Job Title      |
| | (previous value)                 |  ⏹     |
| |                                    |        |
| [6] Active                           |
| |                                    |        |
| [7] Inactive                         |
| +--------------------------------------+
```

**Numbered annotations (Add):**

1. **Close button.** **Required?** N/A. Closes dialog without saving; discards changes.
2. **Save button.** **Required?** N/A. Primary action; validates form and saves new department/job; `hidden` when user lacks Create right.
3. **Code field.** **Required?** Yes (Add) / Read-only (Edit). Input type `text`; auto-generated code for new record; **PROPOSED:** read-only on edit, displays current code (e.g., `dept-001`).
4. **Code display.** **Required?** N/A. **PROPOSED:** shows current code on edit; disabled input with grayed appearance (`bg-gray-100`/`dark:bg-slate-950`, `text-gray-400`/`dark:text-gray-500`).
5. **Department Name / Job Title field.** **Required?** Yes. Input type `text`; uppercase 10px label above; trimmed by handler.
6. **Active/Inactive toggle.** **Required?** N/A. Two radio buttons or pill buttons; Active selected by default; **PROPOSED:** only Admin/Superadmin can toggle inactive status; Users see Active-only.

**Navigation:** Close → dismiss; Save → validates and closes; saves info toast; **PROPOSED:** error toast on validation failure.

**Role/state:** Superadmin/Admin can add/edit any record including toggling Active/Inactive; Users see Add button only for Active-view creations; code read-only on edit prevents field modification.

**Purpose:** Display job positions with department assignment, salary range, and action columns.

**Layout:**

```text
+--------------------------------------+
| [Search]    [Add Job]                |
|                                      |
| +----------------------------+--------+
| | Job Title                  | Actions |
| | ---------------------------- |---------|
| | Software Engineer          | Edit Del  |
| | ---------------------------- |---------|
| | Data Analyst               | Edit Del  |
| | ---------------------------- |---------|
| | HR Manager                 | Edit Del  |
| +----------------------------+--------+
|                                      |
| Active  Inactive  All                |
+--------------------------------------+
```

**Numbered annotations:**

1. **Search field.** **Required?** N/A. Type-ahead filter on job title; magnifying glass icon with sr-only label "Search jobs".
2. **Add Job button.** **Required?** N/A. **PROPOSED:** primary pill button (`btn-primary`) opens add job dialog; hidden when user lacks Create right for Jobs module.
3. **Job Title column.** **Required?** N/A. Position title; includes department prefix if applicable (e.g., "Engineering · Software Engineer").
4. **Department column.** **Required?** N/A. Department name or abbreviation where job resides.
5. **Actions column.** **Required?** N/A. Right-aligned Edit/Delete buttons per user rights; hidden when matching right is absent (no-right variant).
6. **Active/Inactive/All tabs.** **Required?** Admin/Superadmin only. Toggle row visibility; count chips show total per status.

**Navigation:** Search → filter results; Add Job → opens dialog; Edit → opens add/edit dialog with read-only code; Delete → confirm modal with soft-delete; Restore → restores deleted job.

**Role/state:** Superadmin/Admin see all rows + Active/Inactive/All tabs + count chips; Users see active rows only with no tabs, no Status/Stamp columns. No-right variants hide Edit/Delete buttons.