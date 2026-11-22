# S2-UIX-02 - Product and Price History Wireframes

Low-fidelity, grayscale, structure-only wireframes for the Product module and its effective-dated price history. The layouts follow `docs/ui-ux/S1-UIX-01-design-system.md`; no color values are shown below.

**Notation:** `[P]` means **PROPOSED (not in reference)**. `[N]` means **NOT BUILT YET**. “Required?” indicates whether a field or action is required. The built app currently renders Products as “Coming soon. This module is not available yet.”; this document is therefore a reference-and-guide wireframe, not a claim that the screen is implemented.

## 1. Product list - not built yet

**Purpose:** Search and manage product records, and open a product's effective-dated price history.

**Layout:**

```text
+--------------------------------------------------------------------------------+
| PentadERP / WORKSPACE                                                   [1] role |
|                                                                    [2] theme    |
+--------------------------------------------------------------------------------+
|                                                                                |
| [3] PRODUCTS MODULE                                                             |
| [4] Products                                                                    |
|     Search and manage product records.                                          |
|                                                                                |
| +----------------------------------------------------------------------------+ |
| | [5] Search products... [P]                 [6] + Add Product [P]           | |
| |                                                                            | |
| | [7] Active 12 [P]   [8] Inactive 3 [P]   [9] All 15 [P]                    | |
| |                                                                            | |
| | [10] Prod Code | Description | Unit | Current Price | Status [P] | Stamp [P] | Prices / Actions |
| |  ------------------------------------------------------------------------------- |
| | | P-001 | Industrial Widget A | pcs | $45.00 | Active [P] | ... [P] | [11] Prices [12] Edit [13] Delete |
| | | P-002 | No price on record | box | - | Active [P] | ... [P] | [14] Prices [12] Edit [13] Delete |
| | | P-003 | Deleted product | can | $- | Inactive [P] | ... [P] | [14] Restore [P] |
| +----------------------------------------------------------------------------+ |
|                                                                                |
+--------------------------------------------------------------------------------+
```

**Numbered annotations**

1. Header breadcrumb and role badge. **Required?** N/A. Reuses the built `PentadERP / WORKSPACE` breadcrumb and top-right role badge.
2. Theme toggle. **Required?** N/A. Reuses the built light/dark theme control.
3. Module eyebrow/pill, “PRODUCTS MODULE”. **Required?** N/A.
4. Page title and subtitle. **Required?** N/A. “[N] Title: Products. Subtitle: Search and manage product records.” [P] only for exact existing-page wording if not present in the reference.
5. Search field. **Required?** N/A. **[P]** Filters product code, description, or unit as text is entered.
6. Add Product action. **Required?** N/A. Shown only with Product Add right. Opens the Product add form.
7–9. Status tabs. **Required?** N/A. **[P]** Active, Inactive, and All follow the built shared-record pattern. Counts are shown to Administrator/Superadmin only. A normal User sees only active records and does not see tabs.
10. Table. **Required?** N/A. The required reference fields are Prod Code, Description, Unit, and Current Price. Status and Stamp are **[P]** because the reference product table does not show them; they are added here only to reuse the built Customers page pattern and guide soft-delete/stamp behavior.
11. Price/Price Logs action. **Required?** N/A. Opens Price History. The reference label is “Price Logs”; the built app template uses “Price history.” This wireframe uses **“Prices”** as the task's requested action and notes the label should be finalized during implementation.
12. Edit action. **Required?** N/A. Shown only for active products when the signed-in user has Product Edit.
13. Delete action. **Required?** N/A. Shown only with Product Delete. Soft-deletes the product and moves it to Inactive; it is not permanent deletion.
14. Restore action. **Required?** N/A. **[P]** Shown on deleted/inactive rows only to an administrator with Delete right.

**Current-price rule:** [N/P] The list shows “-” when no active, non-future price exists. Otherwise the value is the latest active effective-dated price whose effective date is on or before today. This follows the Sprint 2 plan and prevents a future-dated price from becoming today's current price.

**Role/state variants:**

- **Admin/Superadmin:** [N] Active/Inactive/All tabs and Status/Stamp columns are available; actions follow each assigned right. Admins and superadmins have implicit full access in the built app.
- **User:** [N] The list is active-only, status tabs are hidden, Status/Stamp are hidden, and Add/Edit/Delete/Restore depend on assigned module and price rights.
- **No module rights:** [N] The product route is unavailable or shows an empty/denied state; no add/edit/delete/price action is shown.

**Navigation:** Search → filter matching product rows. Add → Add form. Edit → Edit form. Prices → Price History dialog. Delete → confirm-delete dialog. Restore → restore immediately after permission/API confirmation.

## 2. Product search and filter bar - proposed

**Purpose:** Narrow the product list without changing the page pattern.

**Layout:**

```text
+----------------------------------------------------------------------------+
| [1] Search products...                                                     |
|                                                                            |
| [2] Active 12   [3] Inactive 3   [4] All 15                               |
+----------------------------------------------------------------------------+
```

**Numbered annotations**

1. Search field. **Required?** N/A. Searches visible product text; exact backend matching is an implementation detail not stated in the reference.
2–4. Status tabs. **Required?** N/A. Admin/Superadmin only. Preserve the existing shared-record tab and count treatment.

**Role/state:** Search is visible to anyone who can view products. Status tabs are hidden for normal Users because the guide states users see only active records.

## 3. Product Add/Edit form - not built yet

**Purpose:** Create or edit a product.

**Layout:**

```text
+--------------------------------------------+
| [1] PRODUCTS DETAILS                 [2] X |
| [3] Add Product                            |
|                                            |
| [4] Prod Code                               |
|     +------------------------------------+ |
|     | P-001                              | |
|     +------------------------------------+ |
|                                            |
| [5] Description                             |
|     +------------------------------------+ |
|     |                                    | |
|     +------------------------------------+ |
|                                            |
| [6] Unit Measure                            |
|     +------------------------------------+ |
|     | pcs                                | |
|     +------------------------------------+ |
|                                            |
| [7] Cancel             [8] Save Product    |
+--------------------------------------------+
```

**Numbered annotations**

1. Dialog eyebrow, “PRODUCTS DETAILS”. **Required?** N/A.
2. Close icon. **Required?** N/A. Closes without saving.
3. Dialog title. **Required?** N/A. “Add Product” for create; “Edit Product” for edit.
4. Prod Code. **Required?** Yes for create. Read-only/disabled on edit; the reference identifies this as the product key and the edit handler keeps it read-only.
5. Description. **Required?** Yes in the reference. Prefilled on edit.
6. Unit Measure. **Required?** Yes in the reference. The reference examples include pcs, box, and can.
7. Cancel. **Required?** N/A. Closes without saving.
8. Save action. **Required?** N/A. “Save Product” in the reference; the Add/Edit title remains explicit.

**Validation/navigation:** Required fields block submission. Close/cancel leaves the list unchanged. Success closes the dialog and refreshes the product list.

**Role/state:** Add is shown only with Product Add. Edit is shown only for active products with Product Edit.

## 4. Deleted/Inactive product view - proposed

**Purpose:** Review soft-deleted products and restore them where permitted.

**Layout:**

```text
+----------------------------------------------------------------------------+
| [1] Inactive tab                                                           |
|                                                                            |
| | P-003 | Deleted product | can | $- | Inactive | stamp | [2] Restore    |
+----------------------------------------------------------------------------+
```

**Numbered annotations**

1. Inactive tab. **Required?** N/A. **[P]** Available only to an administrator or superadmin.
2. Restore. **Required?** N/A. **[P]** Shown only with Delete right. Restores the product to Active; no permanent-delete action is designed here.

**Role/state:** Normal Users see active records only and cannot open the Inactive tab or restore. Users cannot soft-delete an inactive product again.

## 5. Price History dialog - not built yet

**Purpose:** Review effective-dated prices for one product and identify which row is current as of today.

**Layout:**

```text
+------------------------------------------------------------------------------+
| [1] PRICE HISTORY                                         [2] X               |
| [3] Price Logs - P-001                                                       |
| [4] Industrial Widget A · pcs                                               |
|                                                                              |
| [5] 3 record(s)                                     [6] + Add Price [P]       |
|                                                                              |
| | Effective Date | Unit Price | Status [P] | Stamp [P] | Actions           |
| |  ------------------------------------------------------------------------ |
| | 2026-12-01 [P] | $48.00 | Future [P] | ... [P] | [7] Edit [P] [8] Delete |
| | 2026-11-22 [P] | $45.00 | CURRENT [P] | ... [P] | [7] Edit [P] [8] Delete |
| | 2026-10-01 [P] | $42.00 | Past [P] | ... [P] | [7] Edit [P] [8] Delete |
|                                                                              |
+------------------------------------------------------------------------------+
```

**Numbered annotations**

1. Dialog eyebrow, “PRICE HISTORY”. **Required?** N/A.
2. Close icon. **Required?** N/A. Closes the history without changing data.
3. Dialog title. **Required?** N/A. The reference uses “Price Logs — [product code]”.
4. Product context. **Required?** N/A. [P] Shows description and unit so the price is not ambiguous.
5. Record count. **Required?** N/A. The reference counts visible price records.
6. Add Price action. **Required?** N/A. Shown only with Price History Add right.
7. Edit action. **Required?** N/A. **[P]** The reference has no edit-price action. Shown only with Price History Edit right.
8. Delete action. **Required?** N/A. Shown only with Price History Delete right. Soft-deletes the price row.

**Status gap:** The reference marks every active/non-deleted price row “Active” and has “—” in its Stamp Log. This wireframe instead proposes three display meanings so users can distinguish effective-date position: **CURRENT**, **Future**, or **Past**. This proposal is **not a fourth database status**. Deleted rows remain Inactive/restoreable according to the built app's status pattern.

**Current rule:** [P] Only the latest active effective-dated row with `effectiveDate <= today` is marked **CURRENT**. Future rows are marked **Future**. Earlier rows are marked **Past**. If there is no non-future row, no row is CURRENT.

**Role/state:**

- **Admin/Superadmin:** Status tabs and Stamp may follow the shared built pattern; price actions follow Price History Add/Edit/Delete rights.
- **User:** Active rows only. No status tabs. Edit/Delete depend on assigned price rights.
- **No rights:** Price history is unavailable unless Product View and/or Price History View is assigned; no mutation actions are shown.

## 6. Product and price soft-delete confirmation - proposed

**Purpose:** Confirm soft deletion of a product or price row.

**Layout:**

```text
+------------------------------------------+
| [1] !                                    |
| [2] Please confirm                       |
| [3] Delete product P-001?                 |
|                                          |
| [4] Cancel       [5] Confirm             |
+------------------------------------------+
```

**Variant - price:** Replace [3] with “Move the 2026-11-22 price to Inactive?”.

**Role/state:** Available only with the matching Delete right. Cancel closes without deleting. Confirm soft-deletes and refreshes the parent list/history.

## 7. Price History add form - not built yet

**Purpose:** Add a dated unit price for a product.

**Layout:**

```text
+--------------------------------------------+
| [1] PRICE DETAILS                   [2] X |
| [3] Add Price                              |
|                                            |
| [4] Product Code                            |
|     +------------------------------------+ |
|     | P-001                              | |
|     +------------------------------------+ |
|                                            |
| [5] Effective Date                          |
|     +------------------------------------+ |
|     | 2026-11-22                          | |
|     +------------------------------------+ |
|                                            |
| [6] Unit Price ($)                          |
|     +------------------------------------+ |
|     | 0.00                                | |
|     +------------------------------------+ |
|                                            |
| [7] Cancel             [8] Save Price      |
+--------------------------------------------+
```

**Numbered annotations**

1. Dialog eyebrow, “PRICE DETAILS”. **Required?** N/A.
2. Close icon. **Required?** N/A.
3. Dialog title. “Add Price”.
4. Product Code. **Required?** N/A. Read-only; populated from the open history.
5. Effective Date. **Required?** Yes. Date field. The reference defaults this to today's date.
6. Unit Price. **Required?** Yes. Numeric, two decimals, minimum 0; the reference calls it Unit Price ($).
7. Cancel. **Required?** N/A. Closes without saving.
8. Save Price. **Required?** N/A. Creates the effective-dated price and refreshes history/current price.

**Role/state:** Visible and usable only with Price History Add right. A normal User must also have Product View/Price History View to open the parent history.

## 8. Price History edit form - proposed

**Purpose:** Change an existing effective-dated price.

**Layout:**

```text
+--------------------------------------------+
| [1] PRICE DETAILS                   [2] X |
| [3] Edit Price [P]                         |
|                                            |
| [4] Product Code                            |
|     +------------------------------------+ |
|     | P-001                              | |
|     +------------------------------------+ |
|                                            |
| [5] Effective Date                          |
|     +------------------------------------+ |
|     | 2026-11-22                          | |
|     +------------------------------------+ |
|                                            |
| [6] Unit Price ($)                          |
|     +------------------------------------+ |
|     | 45.00                               | |
|     +------------------------------------+ |
|                                            |
| [7] Cancel             [8] Save changes    |
+--------------------------------------------+
```

**Numbered annotations**

1–4. Reuse the Add Price dialog structure. Product Code remains read-only.
5. Effective Date. **Required?** Yes. **[P]** Editable in the built app. The effective date identifies the row and affects which price is current.
6. Unit Price. **Required?** Yes. Prefilled.
7. Cancel. **Required?** N/A.
8. Save changes. **Required?** N/A.

**Role/state:** This edit state is **PROPOSED (not in reference)** and is visible only with Price History Edit right. It is not present in the reference price action set.

## 9. Current price as of date helper - proposed

**Purpose:** Let a future sales or pricing workflow choose the applicable unit price without writing a price history row.

**Layout:**

```text
+--------------------------------------------+
| [1] Product: P-001                         |
| [2] Sale date: [2026-11-22]                |
| [3] Unit price: $45.00                     |
+--------------------------------------------+
```

**Numbered annotations**

1. Product Code context. **Required?** N/A.
2. Sale date input. **Required?** Yes for lookup. **[P]** The system uses this date, not today's date.
3. Result. **Required?** N/A. **[P]** Displays the latest active effective-dated price whose effective date is on or before the sale date. Show “-” if no qualifying price exists.

**Navigation:** This helper is read-only and can be reused in Sales. It does not alter price history.

## 10. Screen-flow table

| Screen | Action | Next screen/state |
|---|---|---|
| Product list | Search | Filtered product rows |
| Product list | Add Product | Product Add form |
| Product list | Edit | Product Edit form |
| Product list | Delete | Confirm soft-delete; success refreshes list |
| Product list, Inactive tab [P] | Restore | Restored product returns to Active |
| Product list | Prices | Price History dialog |
| Price History | Add Price | Add Price form |
| Add Price form | Save | History refreshes; current-price helper/list recalculates |
| Price History | Edit [P] | Edit Price form |
| Edit Price form | Save [P] | History refreshes; current-price helper/list recalculates |
| Price History | Delete | Confirm soft-delete; history refreshes |
| Price History, Inactive view [P] | Restore | Restored price returns to Active |
| Sales/current-price helper [P] | Enter sale date | Applicable unit price or “-” |

## 11. Right-based visibility matrix

| View/action | Superadmin/Admin | Assigned User | No-right view |
|---|---|---|---|
| Product list | Yes | Yes only with Product View | No product access |
| Add Product | Yes | Only with Product Add | Hidden |
| Edit Product | Yes | Only with Product Edit | Hidden |
| Delete/Restore Product | Yes | Only with Product Delete for delete/restore | Hidden |
| Active/Inactive/All tabs [P] | Yes | No; active-only | Hidden |
| Price History | Yes | Product View plus Price History View/right | Hidden/unavailable |
| Add Price | Yes | Price History Add | Hidden |
| Edit Price [P] | Yes | Price History Edit | Hidden |
| Delete/Restore Price [P] | Yes | Price History Delete | Hidden |

## 12. Gaps & Assumptions

| Topic | Available source | Gap or decision |
|---|---|---|
| Student guide 3.4/Figures 11-14 | Named guide and figure files were not present in the workspace. The task prompt provides the 3.4/Sprint 2 behavior summary. | Followed the prompt, the Sprint 2 plan, the reference, and the built app facts. Guide-specific exact labels beyond those source summaries remain a gap. |
| Private-Design-Reference | The expected `Private-Design-Reference` folder was absent. The read-only HTML was available at `D:\GitHub_Project\reference_html\PentadERP_index (FINAL).html` and was inspected for the named product/price handlers. | Followed the available HTML for form fields, table structure, labels, current-price sorting, and status text. |
| Built app | Products is not built: the app shows “Coming soon. This module is not available yet.” The built app does contain a shared record pattern and price-history template/JavaScript. | Marked these screen wireframes **not built yet**. Reused the page pattern and rights behavior but did not edit application templates or static assets. |
| Search/tabs/restore | Search/filter, status tabs, and restore are not fully present in the reference product screen. The built app's shared record pattern includes active/inactive/all, search, stamp, and restore. | Marked search, status tabs, and restore **PROPOSED** or in the built-app pattern where applicable. |
| Price status | The reference shows `Active` for every non-deleted price and `—` for stamp. | Replaced only the proposed display semantics with Current/Future/Past; these do not redefine the Active/Inactive database status. Deleted prices remain soft-deleted. |
| Edit price | The reference has add/delete only. | Marked Edit Price and Effective-Date editing **PROPOSED (not in reference)**. |
| Stamp | The reference uses Stamp Log and shows an em dash. The guide requirement for stamp wording was not supplied as a separate file. | Kept “Stamp” in the built-app-pattern proposal and did not invent a stamp format. |
| Current price | The reference `latestUnitPrice` sorts descending and does not explicitly exclude future effective dates. | Followed the Sprint 2 plan and guide summary: select the latest effective price on or before the requested date; future rows do not become current. |
| Price currency | The reference shows `$` and “Unit Price ($).” | Reused the reference currency label; exact currency policy is not changed. |
| Soft delete | The reference product/price handlers mark records deleted locally. The built app template uses Inactive and Restore. | Followed soft delete/restore and marked permanent deletion out of scope. |
