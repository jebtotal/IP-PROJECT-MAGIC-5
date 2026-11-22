# S2-BLD-01 — Customer and Sprint 1 acceptance checks

Apply migrations in filename order through the Supabase Dashboard SQL Editor,
including `20261122000400_s2_bld_01_customers_sprint1.sql`. Use a scratch or
copied database with one Superadmin, one Admin, and one limited User.

## Customer list and lifecycle

1. As Superadmin and Admin, open `/customers`. Confirm Active, Inactive, and
   All tabs show counts, and each row includes Status and Stamp.
2. As a limited User with Customer View, confirm only active customers appear;
   tabs, Status, and Stamp are absent even when requesting `?status=all`.
3. Search by customer number, name, address, and payment terms. Confirm the
   existing `COD`, `30D`, and `45D` values remain available.
4. As a User with Customer Delete, attempt to delete a customer with a row in
   `sales_active`. Expect HTTP 409, an explanation, and no soft deletion.
   Repeat with a customer that has no active sales; expect `is_deleted=true`.
5. As Admin/Superadmin with Customer Delete, restore the inactive customer.
   Confirm it appears as Active and retains its prior business values.
6. Confirm list output maps old stamp prefixes `ADD`, `EDIT`, `DELETE`, and
   `RESTORE` to `CREATED`, `EDITED`, `DELETED`, and `RESTORED` without changing
   the stored stamp. New record changes must store the guide's words, actor,
   and timestamp.

## Rights dialog

For each listed right, give a limited User that right (and the existing
generic module View right when needed to reach the screen). Confirm its
checkbox appears in the correct module, module selection and All/None work,
the assignment is stored in `user_permission` with `is_deleted` and `stamp`,
and saving creates an `audit_log` row with `event_type = user_permission.EDIT`.
Where a matching application route exists, verify the allowed action succeeds
and an unassigned action is rejected server-side. HR, Sales, and Reports
screens/routes not yet present are catalogue/storage and database-policy checks
only; do not treat a visible checkbox as proof of a working feature.

| Module | Rights to exercise individually |
| --- | --- |
| Customer | Add Customer; Edit Customer; Delete Customer |
| Product | Add Product; Edit Product; Delete Product; Add Price; Edit Price; Delete Price |
| Human Resources | Add Job; Edit Job; Delete Job; Add Department; Edit Department; Delete Department; Add Employee; Edit Employee; Delete Employee; View Job History; Add Job History; Edit Job History; Delete Job History |
| Sales | Add Sale; Edit Sale; Delete Sale; View Sale Detail; Add Sale Detail; Edit Sale Detail; Delete Sale Detail |
| Reports | Top Customers; Product Master List; Top Products; Active Employees; All Employees; Employee Job History; Top Sales |

The existing generic module-view rights are retained in addition to the 36
named guide rights.

## Sprint 1 account administration

1. Add a User. Confirm the account is approved, the temporary password works,
   and first login redirects to set-password before the workspace is available.
2. As Superadmin, approve a pending account and make a regular User an Admin.
   Confirm Admin cannot approve a pending User or make an Admin.
3. Block and unblock a User. Confirm `profiles.blocked` changes and a blocked
   account cannot log in or use protected API routes.
4. As Admin, verify Superadmin accounts are absent from list/search results
   and direct edit, status, rights, remove, and restore requests cannot change
   a Superadmin profile.
5. Remove a non-final account. Confirm it remains in `profiles` with
   `is_deleted=true`, disappears from Active, and can be restored. Confirm
   user-management changes are present in `audit_log`.
6. With exactly one active Superadmin, attempt Block and Remove. Both must be
   rejected server-side and the account remains active. With two active
   Superadmins, verify one can be disabled or soft-deleted.
7. Submit a protected mutation without `X-CSRF-Token`; expect HTTP 400. Repeat
   with the rendered token and confirm the request follows normal authorization.

## Source-plan gaps to report

The checked-in Scrum plan describes Sprint 1 outcomes but does not include
the detailed S1-DEV-02..04 criteria. The supplied S1-DEV-05..08 summary covers
user management, approval, rights, and the role-aware main page. The current
app has no HR, Sales, or Reports CRUD/report routes, so those rights cannot be
end-to-end exercised until those module screens are implemented.
