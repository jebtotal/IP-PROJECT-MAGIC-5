# S2-BLD-03 â Price History Gaps, Current Price, and Permissions

## Purpose
This document verifies the permission matrix and acceptance criteria for the Price History / Products module in Sprint 2, confirming that every button/route is properly gated server-side (403 + toast) and that role-based access matches the guide.

## Rights Matrix â Superadmin / Admin / User Ã 36 Guide Rights

The 36 named guide rights are:

| Module | Rights (total) |
|---|---|
| **Customer** | Add Customer; Edit Customer; Delete Customer (3) |
| **Product** | Add Product; Edit Product; Delete Product; Add Price; Edit Price; Delete Price (6) |
| **Human Resources** | Add Job; Edit Job; Delete Job; Add Department; Edit Department; Delete Department; Add Employee; Edit Employee; Delete Employee; View Job History; Add Job History; Edit Job History; Delete Job History (13) |
| **Sales** | Add Sale; Edit Sale; Delete Sale; View Sale Detail; Add Sale Detail; Edit Sale Detail; Delete Sale Detail (7) |
| **Reports** | Top Customers; Product Master List; Top Products; Active Employees; All Employees; Employee Job History; Top Sales (7) |
| **---** | **Total: 36** |

### Pass/Fail Matrix

| Role | Cust Add | Cust Edit | Cust Del | Prod Add | Prod Edit | Prod Del | Prod Add P | Prod Edit P | Prod Del P | HR Add J | HR Edit J | HR Del J | HR Add D | HR Edit D | HR Del D | HR Add E | HR Edit E | HR Del E | HR V JH | HR Add JH | HR Edit JH | HR Del JH | Sales Add | Sales Edit | Sales Del | Sales V SD | Sales Add SD | Sales Edit SD | Sales Del SD | Reps TC | Reps PML | Reps TL | Reps AE | Reps AEmp | Reps EJH | Reps TS |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Superadmin** | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS |
| **Admin** | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS | ✅ PASS |
| **User (limited)** | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL | ❌ FAIL |

**Notes:**
- **Superadmin**: ALL 36 rights pass by virtue of 
ole = 'superadmin' in hope_can_access (app.py:87-89 returns TRUE immediately).
- **Admin**: ALL 36 rights pass because get_permissions_for_user (app.py:356-360) returns {module: {action: True for action in RIGHTS_ACTIONS} for module in RECORD_MODULES} for admin/superadmin roles.
- **User (limited)**: ZERO rights pass by default. Rights are only granted via the user_permission table or legacy user_permissions table. A new registration starts as 'pending' with no module rights. Any right marked ✅ must be explicitly assigned through the User Management interface; otherwise the server returns HTTP 403 with toast 'You do not have permission for this action.'.

## Verification Steps

### 1. Price History âCurrentâ Marker
1. As **Superadmin or Admin**, open a product's price history at /products/<prodCode>/price-history.
2. Observe the table rows: the row whose effDate is least future-dated and not soft-deleted bears a **âCurrentâ** badge in a dedicated column (added in price-history.js).
3. As a **limited User**, open the same page. The âCurrentâ badge appears on the same in-force row (the column is always visible; the badge is purely informational, not action-dependent).

### 2. Products List âCurrent Priceâ
1. As **Superadmin or Admin**, open /products. Confirm the âCurrent Priceâ column is populated from _product_current_price (the SQL view created in migration s2_dba_02_price_as_of.sql).
2. As a **limited User with Product View**, open /products. The âCurrent Priceâ column is visible for every product; inactive/soft-deleted products show âx94.
3. Confirm the price reflects the latest effdate <= CURRENT_DATE from pricehist_active, via the price_as_of(prodcode, date) function.

### 3. Rights Enforcement â Button Hidden + Server 403 + Toast
For each of the 36 rights, verify the following cycle:

| Step | Action | Expected Result |
|---|---|---|
| 1 | Log in as a **User without** the specific right (e.g., no âProduct Deleteâ). | The Delete button is **hidden** from the UI (client-side âcurrentActionsâ check). |
| 2 | Attempt the action manually (e.g., POST /api/records/products or PATCH /api/records/products/<id>/delete). | Server returns **HTTP 403** with error body, and a toast appears: âYou do not have permission for this action.â |
| 3 | Log in as **Admin** or **Superadmin** and assign the right via User Management. | The button reappears, the action succeeds, and a success toast appears. |
| 4 | Repeat for all 36 rights across Customer, Product, Price History, HR, Sales, and Reports modules. | Every right follows the same pattern: hidden when unassigned, 403 + toast when attempted server-side, visible + functional when assigned. |

### 4. Specific Route Checks
- **Product Add**: POST /api/records/products → 403 + toast if User lacks âProduct Addâ right.
- **Product Edit**: PATCH /api/records/products/<prodCode> → 403 + toast if User lacks âProduct Editâ right.
- **Product Delete**: PATCH /api/records/products/<prodCode>/delete → 403 + toast if User lacks âProduct Deleteâ right.
- **Price Add**: POST /api/products/<prodCode>/price-history → 403 + toast if User lacks âproducts.priceHistory.addâ right.
- **Price Edit**: PATCH /api/products/<prodCode>/price-history/<effDate> → 403 + toast if User lacks âproducts.priceHistory.editâ right.
- **Price Delete/Restore**: PATCH /api/products/<prodCode>/price-history/<effDate>/delete / /restore → 403 + toast if User lacks âproducts.priceHistory.deleteâ right (Restore is Admin-only server-side at app.py:1033-1034).

### 5. Inactive/Deleted Row Behavior
- **Customer/Product**: A User without Delete right sees no Delete button. Attempting soft-delete via API returns 409 or 403 with clear message.
- **Price History**: Delete moves row is_deleted = True (soft delete). Restore is Admin-only (server returns 403 for User at app.py:1033-1034).
- **Products list**: Inactive products show Status âInactiveâ and Stamp only for Admin; Users see only active rows, no tabs/Status/Stamp.

## Gaps & Assumptions
- The âprice_as_ofâ function and âv_product_current_priceâ view were confirmed already existing (migration s2_dba_02_price_as_of.sql). This PR only adds the âCurrentâ UI marker.
- The rights matrix assumes a fresh database where no user rights have been pre-assigned beyond the generic module View. In production, rights are assigned per-user through the User Management screen.
- The âCurrentâ badge in price history is informational only; it does not change API behavior or server logic. The server already correctly returns the latest non-future price via âv_product_current_priceâ.
- This matrix is based on the guide's 36 rights and the existing app.py authorization code. If additional rights or modules are added in future sprints, this matrix should be extended.

## How to Check
1. Start the app (âx98python app.pyâ or via Supabase dashboard) with three test accounts: Superadmin, Admin, and a limited User.
2. Log in each account and execute the verification steps above.
3. Use the browser devtools Network tab to confirm 403 responses and toast messages.
4. Verify the âCurrentâ badge appears on the correct row in price history for all role types.

## Extra PR?
no
