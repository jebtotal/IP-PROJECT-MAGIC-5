# S2-UIX-01 - Customer Wireframes

Low-fidelity, structure-only wireframes for the Customer module. The layouts follow `docs/ui-ux/S1-UIX-01-design-system.md`; no color values are shown below.

**Notation:** `[P]` means **PROPOSED (not in reference)**. `Required?` indicates whether a field or action is required. “Not built yet” means the visual/interaction is not present in the built app and is a wireframe from the available reference and guide.

## 1. Customer list - built

**Purpose:** Search and manage customer records.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / WORKSPACE                                                   [1] role |
|                                                                    [2] theme    |
+--------------------------------------------------------------------------------+
|                                                                                |
| [3] CUSTOMERS MODULE                                                           |
| [4] Customers                                                                  |
|     Search and manage customer records.                                        |
|                                                                                |
| +----------------------------------------------------------------------------+ |
| | [5] Search customers...                         [6] + Add Customer          | |
| |                                                                            | |
| | [7] Active 12   [8] Inactive 3   [9] All 15                                | |
| |                                                                            | |
| | [10] Customer No | Customer Name | Address | Payment Terms | Status | Stamp | Actions |
| |  ---------------------------------------------------------------------------  | |
| | | C0001 | Acme Supplies | ... | 30D | Active | [11] ... | [12] Edit [13] Delete |
| | | C0002 | ...          | ... | COD | Inactive | ... | [14] Restore        |
| +----------------------------------------------------------------------------+ |
|                                                                                |
+--------------------------------------------------------------------------------+
```

**Numbered annotations**

1. Header breadcrumb and role badge. **Required?** N/A. PentadERP / WORKSPACE is the built breadcrumb. The top-right role badge shows Admin or Superadmin for role-aware views.
2. Theme toggle. **Required?** N/A. Switches light/dark theme.
3. Module eyebrow/pill, “CUSTOMERS MODULE”. **Required?** N/A. Reuses the built module-pill treatment.
4. Page title and subtitle. **Required?** N/A. Large title “Customers” and the existing subtitle “Search and manage customer records.”
5. Search field. **Required?** N/A. Filters the customer list as text is entered.
6. Add action. **Required?** N/A. Shown only when the signed-in user has the Customer Add right. Opens the Add Customer dialog.
7–9. Status tabs. **Required?** N/A. Active, Inactive, and All are shown to Admin/Superadmin only. Each tab includes its built record count. Users use the active-only API view and do not see tabs.
10. Table. **Required?** N/A. The built columns are Customer No, Customer Name, Address, Payment Terms, Status, Stamp, and Actions for Admin/Superadmin. **Payment Terms** uses the built options COD, 30D, and 45D.
11. Stamp. **Required?** N/A. The built table shows the record stamp string supplied by the app.
12. Edit action. **Required?** N/A. Shown only for active records when the signed-in user has Customer Edit.
13. Delete action. **Required?** N/A. Shown for active records with Customer Delete. Moves the record to Inactive; it is not permanent deletion.
14. Restore action. **Required?** N/A. Shown for deleted/inactive records only to an administrator with Delete right. Calls the Restore API and returns the record to active use.

**Navigation:** Search → refresh matching active/inactive/all rows. Add → Add form. Edit → Edit form. Delete → confirm-delete dialog. Restore → restore immediately after permission and API confirmation success.

**Role/state:** Built for Admin/Superadmin and User. The list is server-filtered and server-authorized.

## 2. Customer Add/Edit form - built

**Purpose:** Create or edit a customer.

**Layout:**

```text
+--------------------------------------------+
| [1] CUSTOMERS DETAILS                 [2] X |
| [3] Add customer                           |
|                                            |
| [4] Customer No                            |
|     +------------------------------------+ |
|     | C0001                              | |
|     +------------------------------------+ |
|                                            |
| [5] Customer Name                          |
|     +------------------------------------+ |
|     |                                    | |
|     +------------------------------------+ |
|                                            |
| [6] Address                                |
|     +------------------------------------+ |
|     |                                    | |
|     +------------------------------------+ |
|                                            |
| [7] Payment Terms                          |
|     [ COD / 30D / 45D                 v ] |
|                                            |
| [8] Cancel             [9] Add customer   |
+--------------------------------------------+
```

**Numbered annotations**

1. Dialog eyebrow, “CUSTOMERS DETAILS”. **Required?** N/A.
2. Close icon. **Required?** N/A. Closes the dialog without saving.
3. Dialog title. **Required?** N/A. “Add customer” for create; “Edit customer” for edit.
4. Customer No. **Required?** Yes for create. Read-only/disabled on edit; the key cannot be changed. This follows the built form behavior.
5. Customer Name. **Required?** Yes.
6. Address. **Required?** No.
7. Payment Terms. **Required?** Yes. Built options are COD, 30D, and 45D.
8. Cancel. **Required?** N/A. Closes the dialog without saving.
9. Save action. **Required?** N/A. “Add customer” on create and “Save changes” on edit.

**Edit variant:** Replace [3] with “Edit customer”, prefill all editable values, show Customer No as disabled/read-only, and replace [9] with “Save changes”. The Customer No is not sent in the edit API body.

**Validation/navigation:** Required fields block submission. The form shows an inline error if save fails. Success closes the dialog, shows a toast, and reloads the list.

**Role/state:** Only users with Customer Add can open the Add state; only users with Customer Edit can open the Edit state.

## 3. Confirm delete - built

**Purpose:** Confirm soft deletion before moving a customer to Inactive.

**Layout:**

```text
+------------------------------------------+
| [1] !                                    |
| [2] Please confirm                       |
| [3] Move Acme Supplies to Inactive?      |
|                                          |
| [4] Cancel       [5] Confirm             |
+------------------------------------------+
```

**Numbered annotations**

1. Warning icon. **Required?** N/A. Reuses the built confirmation treatment.
2. Heading, “Please confirm”. **Required?** N/A.
3. Confirmation copy. **Required?** N/A. Names the customer and states “Move ... to Inactive?”
4. Cancel. **Required?** N/A. Dismisses and leaves the record active.
5. Confirm. **Required?** N/A. Executes soft delete; success reloads the list and shows a toast.

**Role/state:** Available only to a signed-in user with Customer Delete. The delete row action uses the built danger button style.

## 4. Deleted/Inactive view - partially built

**Purpose:** Review soft-deleted customers and restore records where permitted.

**Layout:**

```text
+----------------------------------------------------------------------------+
| [1] CUSTOMERS MODULE                                                       |
| [2] Customers                                                              |
| Search and manage customer records.                                        |
|                                                                            |
| [3] Search customers...                                                    |
|                                                                            |
| [4] Active 12   [5] Inactive 3   [6] All 15                                |
|                                                                            |
| [7] Customer No | Customer Name | Address | Payment Terms | Status | Stamp | Actions |
| | C0002 | ... | ... | 30D | Inactive | ... | [8] Restore                  |
+----------------------------------------------------------------------------+
```

**Numbered annotations**

1–3. Same module heading and search behavior as the customer list.
4–6. Status tabs. The Inactive tab is selected in this variant.
7. Table. Deleted rows use the built Inactive status and remain in the administrator view.
8. Restore action. **Required?** N/A. Visible only to Admin/Superadmin with the Delete right because restore is implemented beside soft-delete rights in the built app. It calls the restore API; success moves the row back to Active.

**Role/state:** Not visible to ordinary Users. Users are forced to `status=active` and receive active rows only. Admin/Superadmin can select Inactive or All and see deleted rows.

**Not built yet:** The current app exposes this deleted view, restore action, and API behavior. The guide-specific labels and copy listed in Gaps & Assumptions are not fully verified and need alignment.

## 5. Role and rights variants

### 5.1 Admin/Superadmin

```text
+------------------------------------------------------------------------+
| Customers                                                             |
| Search and manage customer records.                                   |
|                                                                        |
| Search [12] + Add                                                      |
| Active [n]   Inactive [n]   All [n]                                   |
|                                                                        |
| Customer No | Name | Address | Terms | Status | Stamp | Actions        |
| ...                                   [Edit] [Delete]                   |
+------------------------------------------------------------------------+
```

- Status and Stamp columns are shown.
- Active/Inactive/All tabs and counts are shown.
- Deleted rows can appear in Inactive or All.
- Add/Edit/Delete depend on assigned rights; Superadmin and the built app's Admin role receive the module access behavior described by the app.
- Restore is available on deleted rows for administrators with Delete right.

### 5.2 User

```text
+------------------------------------------------------------------------+
| Customers                                                             |
| Search and manage customer records.                                   |
|                                                                        |
| Search [12]                                                             |
|                                                                        |
| Customer No | Name | Address | Terms | Actions                          |
| ...                                                                     |
+------------------------------------------------------------------------+
```

- No status tabs.
- No Status or Stamp columns.
- Only active records are loaded.
- No deleted rows or Restore action.
- Add/Edit/Delete controls depend on separate rights.

### 5.3 User without Add/Edit/Delete rights

```text
+------------------------------------------------------------------------+
| Customers                                                             |
| Search and manage customer records.                                   |
|                                                                        |
| Search [12]                                                             |
|                                                                        |
| Customer No | Name | Address | Terms | Actions                          |
| ...                                          —                         |
+------------------------------------------------------------------------+
```

- View remains usable only if the user has Customer View.
- Add button is absent.
- Edit action is absent.
- Delete action is absent.
- Actions cell shows em dash if no rights remain.

**Not built yet:** A guide-complete customer module is not a separate reference screen; these variants describe the built shared-record template plus the guide's role/soft-delete rules.

## 6. Gaps & Assumptions

| Topic | Built app/reference behavior | Guide/sprint requirement | Decision for this wireframe |
|---|---|---|---|
| Payment terms | Built field options are COD, 30D, and 45D. | Guide text names “Net 30” (as stated in the task). | Follow the built app and database constraint for the implementation labels; note that guide alignment is needed. `Net 30` is not shown as an option. |
| Stamp wording | Built Stamp column is the app-provided stamp string; delete/restore logic currently exposes that stamp field. | Guide specifies CREATED/EDITED/DELETED-style stamp wording. | Preserve the built column name “Stamp” and mark exact wording as a gap. This wireframe does not invent a replacement format. |
| Delete button style | Built row Delete uses `.btn-danger`, and confirmation uses the built red `Confirm` button. | The guide's delete style is not available in the supplied workspace. | Follow the built app's red danger treatment. |
| Restore | Built app and shared record template include Restore for Admin/Superadmin with delete right. | Sprint 2 requires permitted administrators to restore customers. | Follow the sprint plan and built app; Restore is shown on deleted rows for administrators. |
| Guide source | The named `Hope Inc. student guide` and `Figures 9-10` were not present as files in the workspace. | Guide 3.3 is required to define exact customer behavior and labels. | Followed the Sprint 2 plan in `docs/scrum/SPRINT_1_BOARD_AND_8_WEEK_MODULE_PLAN.md`, the built Customer template/JavaScript, and the design-system source. Guide-specific discrepancies are recorded above. |
| Reference source | `Private-Design-Reference` was not present; the prior design document says the expected named HTML was unavailable. | Reference should control look and customer handlers. | Reused the existing built Customer screen and existing design-system tokens. Customer-specific handler details are treated as built implementation facts, not invented reference visuals. |

**Source priority applied:** where a source disagreement exists, this wireframe follows the built app for visible structure and labels, and the Sprint 2 plan for role/soft-delete behavior. Missing guide/reference facts are left as gaps rather than invented.
