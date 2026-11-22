# S2-BLD-02 — Products module acceptance checks

Apply migrations in filename order through the Supabase Dashboard SQL Editor,
including all S2-DBA migrations (customer_product_active, price_as_of,
validation_constraints, search_indexes). Use a scratch or copied database with
one Superadmin, one Admin, and one limited User. The database already holds 57
products; no demo rows are added.

## Products list page

1. As Superadmin and Admin, open `/products`. Confirm the list shows columns:
   Prod Code, Description, Unit, Current Price (or "—"), Status, Stamp,
   Actions (Price history / Edit / Delete). Confirm Active, Inactive, and All
   tabs show counts.
2. As a limited User with Product View, confirm only active products appear;
   tabs, Status, and Stamp are absent even when requesting `?status=all`.
   Current Price should still be visible.
3. Search by product code, description, and unit. Confirm results filter
   server-side.
4. Confirm Current Price shows the latest non-future effective-date price from
   `v_product_current_price`, or "—" when no price exists. Confirm inactive
   products show "—" for Current Price.

## Products lifecycle

5. As a User with Product Add, open the Add Product modal. Confirm the form
   has Product Code, Description, and Unit fields. Submit valid data and
   confirm the product appears as Active. Confirm `stamp` stores CREATED.
6. As a User with Product Edit, edit a product's Description and Unit. Confirm
   the Product Code field is read-only on edit. Confirm `stamp` stores EDITED.
7. As a User with Product Delete, attempt to delete a product that has a row
   in `pricehist_active` or `salesdetail_active`. Expect HTTP 409 with a clear
   message and no soft deletion. Repeat with a product that has no active
   children; expect `is_deleted=true`.
8. As Admin/Superadmin with Product Delete, restore the inactive product.
   Confirm it appears as Active and retains its prior business values.

## Price history (from product list)

9. From the product list, click "Price history" on a product. Confirm the
   price history page opens for that product. Confirm Add/Edit/Delete price
   entries work according to assigned Price History rights.
10. Confirm creating a price with a future effective date is allowed (no
    future-date restriction in the UI; `price_as_of` only returns non-future
    prices for current price lookups).

## Rights enforcement

11. Confirm Add/Edit/Delete Product rights are enforced on the server for every
    request. A User without Product Add cannot POST `/api/records/products`.
    A User without Product Edit cannot PATCH `/api/records/products/<id>`.
    A User without Product Delete cannot PATCH
    `/api/records/products/<id>/delete`.
12. Confirm Superadmin accounts cannot be seen or edited by Admin in user
    management (separate from Products, but part of Sprint 1 rights).

## Source-plan gaps to report

The checked-in Scrum plan describes Sprint 1 outcomes but the Products module
frontend (Current Price column, product delete guard) was not present before
this PR. HR, Sales, and Reports screens/routes remain catalogue/storage and
database-policy checks only; do not treat a visible checkbox as proof of a
working feature.
