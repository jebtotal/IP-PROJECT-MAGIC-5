# S1-UIX-03 — Main Page and User Management Wireframes

Low-fidelity grayscale layouts based on `PentadERP_index (FINAL).html`. These are structural, not visual mockups. Shared modal/card/input/table conventions follow `docs/ui-ux/S1-UIX-01-design-system.md`; no color values are represented.

**Notation:** `[P]` means **PROPOSED (not in reference)**. `View` refers to the module's `.view` permission.

## 1. Main page — Superadmin

**Purpose:** Executive dashboard and full application navigation.

**Layout:**

```text
+----------------------+----------------------------------------------+
| [1] PentadERP         | [8] Dashboard Overview  [9] Superadmin [10] |
|                      +----------------------------------------------+
| [2] Executive        | [11] Welcome back, Sarah!                    |
|     Analytics        |      Full system access...                   |
| [3] Customer CRM     |                                              |
| [4] Product Catalog  | [12] Total Customers [13] Products           |
| [5] Human Resources  |      [14] Open Orders   [15] Revenue (MTD)   |
| [6] Sales Operations +----------------------------------------------+
| [7] Executive Reports| [16] Revenue Performance Analytics           |
|     User Management |      +--------------------------------------+ |
|                      |      | [17] Chart                          | |
|                      |      +--------------------------------------+ |
|                      |                         +------------------+ |
|                      |                         | [18] Quick Nav   | |
|                      |                         | Customers        | |
|                      |                         | Products         | |
|                      |                         | HR               | |
|                      |                         | Sales            | |
|                      |                         | Reports          | |
|                      |                         | Manage Users     | |
|                      |                         | [19] Security    | |
|                      +-------------------------+------------------+ |
| [20] Avatar / Name / Role / Logout                                  |
+----------------------------------------------------------------------+
```

**Numbered annotations**

1. Brand mark/wordmark in sidebar header. **Required?** N/A. Reference includes `.pentad-logo` and PentadERP.
2. Dashboard/Executive Analytics nav item. **Required?** N/A. Always listed; active item uses selected treatment.
3–6. Customer CRM, Product Catalog, Human Resources, and Sales Operations nav items. **Required?** N/A. Each appears for Superadmin; `can()` grants Superadmin all permissions.
7. Executive Reports and User Management nav items. **Required?** N/A. Reports appears; User Management is admin-only and therefore appears to Superadmin.
8. Page title. **Required?** N/A. Dynamic header title, “Dashboard” when the dashboard is selected.
9. Role badge. **Required?** N/A. Displays current role.
10. Theme toggle. **Required?** N/A. Switches light/dark theme.
11. Welcome banner. **Required?** N/A. Includes personalized greeting and role-specific access summary.
12–15. Four stat cards: Total Customers, Products, Open Orders, Revenue (MTD). **Required?** N/A. Values/captions and accent icons are reference dashboard content.
16. Revenue Performance Analytics card/title and fiscal badge. **Required?** N/A. Contains chart area.
17. Revenue chart canvas. **Required?** N/A. Drawn by `renderDashboardRevenueChart`.
18. Quick Navigation card. **Required?** N/A. Reference adds shortcuts for five modules and Manage Users for non-User roles. The User version is not filtered by View permissions in the current renderer; filtering it consistently is **PROPOSED (not in reference)**.
19. Active Security callout. **Required?** N/A. States audit-backed soft delete is enabled.
20. Sidebar account footer: avatar, name, role, logout. **Required?** N/A. Logout action returns to landing.

**Role/rights visibility:** Superadmin bypasses individual permission checks and sees all sidebar items, including User Management. Quick Navigation includes all module shortcuts and Manage Users.

## 2. Main page — Admin

**Purpose:** Same executive dashboard with Admin-specific welcome copy and navigation.

**Layout:**

```text
+----------------------+----------------------------------------------+
| [1] PentadERP         | [8] Dashboard Overview  [9] Admin      [10] |
|                      +----------------------------------------------+
| [2] Executive        | [11] Welcome back, Lisa!                     |
|     Analytics        |      Manage most modules and user rights...  |
| [3] Customer CRM     |                                              |
| [4] Product Catalog  | [12] Total Customers [13] Products           |
| [5] Human Resources  |      [14] Open Orders   [15] Revenue (MTD)   |
| [6] Sales Operations +----------------------------------------------+
| [7] Executive Reports| [16] Revenue Performance Analytics           |
|     User Management |      +--------------------------------------+ |
|                      |      | [17] Chart                          | |
|                      |      +--------------------------------------+ |
|                      |                         +------------------+ |
|                      |                         | [18] Quick Nav   | |
|                      |                         | Customers        | |
|                      |                         | Products         | |
|                      |                         | HR / Sales       | |
|                      |                         | Reports          | |
|                      |                         | Manage Users     | |
|                      |                         | [19] Security    | |
|                      +-------------------------+------------------+ |
| [20] Avatar / Name / Role / Logout                                  |
+----------------------------------------------------------------------+
```

**Numbered annotations:** Items [1]–[10] and [12]–[20] match the Superadmin variant. [11] uses the Admin welcome message. Admin receives all module View rights via the reference `can()` behavior.

**Role/rights visibility:** `renderSidebar` allows both Admin and Superadmin to see User Management; `can()` grants Admin all permissions. The welcome message says Admin manages most modules and user rights except Superadmin accounts. However, the current `renderUserManagement` renderer does not filter Superadmin records or restrict editing by role. Hiding Superadmin accounts and limiting Admin management to Users is **PROPOSED (not in reference)** and is required for the proposed User Management variant below.

## 3. Main page — User with limited rights

**Purpose:** Dashboard for a User assigned only selected module View rights. Example rights: `customers.view` and `sales.view`; other module View rights are false.

**Layout:**

```text
+----------------------+----------------------------------------------+
| [1] PentadERP         | [8] Dashboard Overview  [9] User       [10] |
|                      +----------------------------------------------+
| [2] Executive        | [11] Welcome back, Alex!                     |
|     Analytics        |      Access to assigned core modules...      |
| [3] Customer CRM     |                                              |
| [4] Sales Operations +----------------------------------------------+
|                      | [12] Total Customers [13] Products           |
|                      |      [14] Open Orders   [15] Revenue (MTD)   |
|                      +----------------------------------------------+
|                      | [16] Revenue Performance Analytics           |
|                      |      +--------------------------------------+ |
|                      |      | [17] Chart                          | |
|                      |      +--------------------------------------+ |
|                      |                         +------------------+ |
|                      |                         | [18] Quick Nav   | |
|                      |                         | Customers        | |
|                      |                         | Sales            | |
|                      |                         | [19] Security    | |
|                      +-------------------------+------------------+ |
| [20] Avatar / Name / Role / Logout                                  |
+----------------------------------------------------------------------+
```

**Numbered annotations:** Items [1]–[20] match the Superadmin variant, with [11] showing User access copy. Sidebar items [3] and [4] are the only module nav entries in this limited-rights example. Product, HR, Reports, and User Management are omitted.

**Role/rights visibility:** `renderSidebar` checks `canModule(module)` for role `user`, so module items without `*.view` are hidden; User Management is also admin-only. The sample user's default rights in the reference include View for all five business modules, but this wireframe intentionally shows the requested limited-rights case. The reference Quick Navigation currently renders all five business shortcuts for Users without checking View rights; hiding unauthorized shortcuts in Quick Navigation is **PROPOSED (not in reference)**.

## 4. User Management list

**Purpose:** Review and maintain accounts, roles, status, and permissions. Existing columns and Add/Edit/Rights actions are shown alongside requested Sprint controls.

**Layout — Superadmin:**

```text
+---------------------------------------------------------------+
| [1] User Management                         [2] + Add User    |
|                                                               |
| [3] Name | Email | Role | Status | Actions                   |
| ---------+-------+------+--------+---------------------------|
| Sarah... | ...   | Superadmin | Active | [4] Edit             |
| Lisa...  | ...   | Admin      | Active | [4] Edit             |
| Alex...  | ...   | User       | Active | [5] Rights [4] Edit |
| Pat...   | ...   | User       | Pending| [6] Approve [7] Edit|
| Sam...   | ...   | User       | Blocked| [8] Unblock [5][4] |
|                                                               |
| [9] Designate Admin (selected User row)                       |
+---------------------------------------------------------------+
```

**Layout — Admin (proposed restricted view):**

```text
+---------------------------------------------------------------+
| [1] User Management                         [2] + Add User    |
|                                                               |
| [3] Name | Email | Role | Status | Actions                   |
| ---------+-------+------+--------+---------------------------|
| Alex...  | ...   | User | Active | [5] Rights [4] Edit [8]  |
| Pat...   | ...   | User | Pending| [6] Approve [4]           |
| Sam...   | ...   | User | Blocked| [7] Unblock [4]           |
|                                                               |
| Superadmin accounts are not shown.                            |
+---------------------------------------------------------------+
```

**Numbered annotations**

1. User Management heading. **Required?** N/A. Reference heading.
2. Add User button. **Required?** N/A. Present in reference; opens Add User dialog.
3. Table columns: Name, Email, Role, Status, Actions. **Required?** N/A. These are the reference columns; rows are horizontally scrollable at narrow widths.
4. Edit action. **Required?** N/A. Present for each listed account in the reference; opens Edit User dialog.
5. Rights action. **Required?** N/A. Reference label is “Rights Matrix”; rendered only for rows whose role is `user`.
6. Approve pending user. **Required?** N/A. **PROPOSED (not in reference):** available for a pending User; changes status to active.
7. Block user. **Required?** N/A. **PROPOSED (not in reference):** available for an active User; changes status to blocked.
8. Unblock user. **Required?** N/A. **PROPOSED (not in reference):** available for a blocked User; returns status to active.
9. Designate Admin. **Required?** N/A. **PROPOSED (not in reference):** promotes an eligible User to Admin. Show for Superadmin only.

**Role/rights visibility rules**

- **Superadmin:** Reference sidebar exposes User Management. The unfiltered reference list shows every account; Rights Matrix appears only on `user` rows, while Edit appears on all rows. Proposed status actions apply to User records. Designate Admin is proposed for Superadmin.
- **Admin:** User Management nav is visible in the reference. The welcome copy states Admin cannot manage Superadmin accounts, but the list does not enforce that claim. This wireframe hides Superadmin rows and limits Admin to managing User accounts as **PROPOSED (not in reference)**. Admin may approve/block/unblock Users in the proposed Sprint controls. Designate Admin remains Superadmin-only in this proposal.
- **User:** User Management nav is omitted by the reference `adminOnly` check; no list access.

## 5. Add/Edit User dialog

**Purpose:** Create an account or update account profile, role, and status.

**Layout:**

```text
+--------------------------------------+
| [1] Add User Account       [2] Close |
|                                      |
| [3] First Name    [4] Last Name     |
|     +-----------+     +-----------+  |
| [5] Email                            |
|     +----------------------------+   |
| [6] Role          [7] Status      |
|     +-----------+     +-----------+  |
|                                      |
| [8] Save User          [9] Cancel    |
+--------------------------------------+
```

**Numbered annotations**

1. Dialog title. **Required?** N/A. Reference changes between “Add User Account” and “Edit User Account”.
2. Close icon/button. **Required?** N/A. Closes dialog without saving.
3. First Name, type `text`. **Required?** Yes.
4. Last Name, type `text`. **Required?** Yes.
5. Email, type `email`. **Required?** Yes. Editable on add; read-only on edit.
6. Role, select. **Required?** Yes. Reference options: User, Admin, Superadmin. For the proposed restricted Admin workflow, Admin may only create/manage User accounts; role restriction is **PROPOSED (not in reference)**. Superadmin can select any role.
7. Status, select. **Required?** Yes. Reference options: Active, Pending, Blocked. Add initializes the select value through form behavior; edit loads stored status.
8. Save User. **Required?** N/A. Saves fields; closes, rerenders list, and shows success toast.
9. Cancel. **Required?** N/A. Closes without saving.

**Role/rights visibility:** The reference modal does not distinguish fields by actor role. The proposed Admin restriction to User accounts and the proposed designation workflow are listed above; current add/edit helpers expose all three role choices regardless of current actor.

## 6. Rights dialog

**Purpose:** Assign per-module View and action permissions to a User.

**Layout:**

```text
+----------------------------------------------------+
| [1] Rights — Alex Rivera                 [2] Close|
| [3] [All] [None]                         [P]       |
|                                                    |
| [4] Customer Management                            |
|     [ ] View Customers  [ ] Add Customer           |
|     [ ] Edit Customer   [ ] Delete Customer        |
| [5] Product Management                             |
|     [ ] View Products   [ ] Add Product            |
|     [ ] Edit Product    [ ] Delete Product         |
| [6] Human Resources                               |
|     [ ] View HR         [ ] Add Job                |
|     [ ] Edit Job        [ ] Delete Job             |
|     [ ] Add Department  [ ] Edit Department        |
|     [ ] Delete Department [ ] Add Employee         |
|     [ ] Edit Employee   [ ] Delete Employee        |
|     [ ] View Job History [P]                       |
| [7] Sales                                          |
|     [ ] View Sales      [ ] Add Sale               |
|     [ ] Edit Sale       [ ] Delete Sale            |
|     [ ] View Sale Detail [P] [ ] Add Detail [P]    |
|     [ ] Edit Detail [P] [ ] Delete Detail [P]      |
| [8] Reports                                        |
|     [ ] View Reports    [ ] View Top Customers [P] |
|     [ ] View Products Master [P]                   |
| [9] Last-superadmin guard [P]                      |
| [10] Save Matrix                 [11] Cancel       |
+----------------------------------------------------+
```

**Numbered annotations**

1. Dynamic dialog heading, “Rights — [user name]”. **Required?** N/A. Reference title.
2. Close button. **Required?** N/A. Closes without saving.
3. All / None buttons. **Required?** N/A. **PROPOSED (not in reference):** set all permission checkboxes on/off. Avoid applying All to a protected final-superadmin assignment unless guard behavior permits it.
4. Customer Management group: module checkbox `customers.view` (“View Customers”), plus action checkboxes `.add` (“Add Customer”), `.edit` (“Edit Customer”), `.delete` (“Delete Customer”). **Required?** N/A. These are all reference rights; the View permission is the module-level checkbox. There is no additional parent checkbox in the reference.
5. Product Management group: module checkbox `products.view` (“View Products”), plus action checkboxes `.add`, `.edit`, `.delete`. **Required?** N/A. Existing reference rights.
6. Human Resources group: module checkbox `hr.view` (“View HR”), plus action checkboxes `hr.jobAdd`, `hr.jobEdit`, `hr.jobDelete`, `hr.deptAdd`, `hr.deptEdit`, `hr.deptDelete`, `hr.empAdd`, `hr.empEdit`, `hr.empDelete`. **Required?** N/A. Existing reference rights. `hr.jobHistory.view` (“View Job History”) is **PROPOSED (not in reference)**.
7. Sales group: module checkbox `sales.view` (“View Sales”), plus action checkboxes `.add` (“Add Sale”), `.edit` (“Edit Sale”), `.delete` (“Delete Sale”). **Required?** N/A. Existing reference rights. `sales.details.view`, `.add`, `.edit`, `.delete` (“View Sale Detail”, “Add Sale Detail”, “Edit Sale Detail”, “Delete Sale Detail”) are **PROPOSED (not in reference)**; current line-item list/add form is not separately permission-gated.
8. Reports group: module checkbox `reports.view` (“View Reports”). **Required?** N/A. Existing reference right, with no child action checkboxes. `reports.topCustomers.view` (“View Top Customers Report”) and `reports.productsMaster.view` (“View Products Master Report”) are **PROPOSED (not in reference)**; these correspond to the two tabs shown by the reference Reports screen.
9. Last-superadmin guard message. **Required?** N/A. **PROPOSED (not in reference):** prevent removal/demotion of the final Superadmin and explain why the action is unavailable. The reference has no such guard in its rights form.
10. Save Matrix. **Required?** N/A. Present in the reference; persists the draft rights, closes the dialog, rerenders the user list, and shows a success toast.
11. Cancel. **Required?** N/A. Present in the reference; closes without saving.

**Role/rights visibility:** The reference renders the Rights Matrix button only for a user whose role is exactly `user`; Admin and Superadmin rows do not show it. `openUmRights` and the form itself do not enforce an actor-role restriction. Proposed Admin access is limited to Users per the list rules; use the dialog for User records only. The final-superadmin guard is proposed and should not be mistaken for existing protection.

## Screen flow

| Screen | Action | Next screen |
|---|---|---|
| Main dashboard | Select User Management (Superadmin/Admin only) | User Management list |
| User Management list | Select Add User | Add User dialog |
| User Management list | Select Edit | Edit User dialog |
| User Management list | Select Rights Matrix on a User row | Rights dialog |
| Add/Edit User dialog | Save User | Updated User Management list |
| Add/Edit User dialog | Cancel or close | User Management list |
| Rights dialog | Save Matrix | Updated User Management list |
| Rights dialog | Cancel or close | User Management list |
| User Management list | Approve pending / Block / Unblock | Updated list with changed status (**PROPOSED**) |
| User Management list | Designate Admin | Updated list with promoted role (**PROPOSED**) |

## Gaps & Assumptions

- The expected `Private-Design-Reference` folder was unavailable. The exact-named HTML was available at `reference_html/PentadERP_index (FINAL).html` and was inspected read-only.
- `ALL_PERMS` defines **23** rights in the reference: Customers 4, Products 4, HR 10, Sales 4, Reports 1. The Sprint plan's 36-right target is 13 more than this reference catalogue.
- The reference Reports screen exposes two report tabs. Proposed per-report rights listed here are `reports.topCustomers.view` and `reports.productsMaster.view`.
- Proposed Sale Detail rights listed here are `sales.details.view`, `sales.details.add`, `sales.details.edit`, and `sales.details.delete`. Proposed Job History right is `hr.jobHistory.view`. These seven named additions do not account for all 13 rights implied by the 36-right target; the remaining six rights are not specified by the task/reference and are intentionally not invented.
- The reference Rights button appears only for accounts with role `user`; it does not appear on Admin or Superadmin rows.
- The reference User Management list uses all accounts without filtering. Its Edit action appears for every row, and its add/edit role selector offers User, Admin, and Superadmin. The Admin restriction to hide Superadmin accounts and manage Users only is a required **PROPOSED (not in reference)** behavior; the reference welcome copy says Admin cannot manage Superadmin accounts but the renderer does not enforce it.
- Block, Unblock, Approve pending user, Designate Admin, All/None rights controls, module-parent checkboxes distinct from View rights, and the final-superadmin guard are **PROPOSED (not in reference)**.
- Sidebar visibility is implemented by role and, for User roles, module View permissions. The default sample User has View rights for all five modules; the limited-rights User wireframe uses an illustrative subset. Quick Navigation currently shows all module shortcuts to Users without View checks; filtering unauthorized shortcuts is **PROPOSED (not in reference)** for consistency.
