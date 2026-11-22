# S2-UIX-05b — Usability Review Fixes (UI Owner)

## Fixed

### S2UX05-06: Price History — Stamp column header terminology
- **Screen:** Price History
- **Change:** Column header changed from `"Stamp"` to `"Stamp Log"` in `my-web-app/templates/price_history.html` (line 54), matching the S2 mockup/reference terminology
- **Rationale:** The built app used "Stamp" as the column header, while the S2 mockup and design system reference use "Stamp Log". Harmonizing the terminology improves consistency across the product.

## Not fixed (why)

### S2UX05-01: Customer list — Add button hidden by default
- **Owner:** Developer
- **Reason:** Fix requires removing the `hidden` attribute from the Add button and implementing right-check logic to show the button when the user has the Create right for the Customers module. This involves JavaScript and/or Python route logic that is outside the UI designer's scope. Per the token rules, no .py, form actions, field names, IDs, or CSRF tokens may be modified.

### S2UX05-02: Customer list — Right visibility not wired for action buttons
- **Owner:** Developer
- **Reason:** Action buttons (Edit, Delete) need to be conditionally rendered based on the user's module-specific Customer Edit/Customer Delete rights. This requires changes to the template conditional logic and/or Python backend route logic. UI designer cannot modify form actions, field names, IDs, or Python code.

### S2UX05-03: Products list — Add button hidden by default
- **Owner:** Developer
- **Reason:** Fix requires removing the `hidden` attribute from the Add Product button and implementing right-check logic based on the Create right for the Products module. This involves JavaScript and/or Python changes outside the UI designer's scope.

### S2UX05-04: Products list — Right visibility not wired for action buttons
- **Owner:** Developer
- **Reason:** Action buttons (Edit, Delete) need to be conditionally rendered based on Product Edit/Product Delete rights. Requires template and/or Python backend changes that the UI designer cannot touch.

### S2UX05-05: Price History — Add button hidden by default
- **Owner:** Developer
- **Reason:** Fix requires removing the `hidden` attribute from the Add Price button and implementing right-check logic based on the Create right for the Price History module. This involves JavaScript and/or Python changes outside the UI designer's scope.

### S2UX05-07: Price History — Sale-date helper UI logic not implemented
- **Owner:** Developer
- **Reason:** The sale-date helper UI is present in the template, but the JavaScript logic in `price-history.js` that implements "latest active effective price on or before sale date" is not in the static template. This requires backend/data logic changes that the UI designer cannot modify.

## For developers

1. The only UI-owned fix (S2UX05-06) has been applied: column header in `price_history.html` changed from "Stamp" to "Stamp Log".
2. Remaining High/Medium items (S2UX05-01, 02, 03, 04, 05, 07) are Developer-owned and involve:
   - Right-gated button visibility (conditional rendering based on module-specific rights)
   - Add button enabled/disabled logic
   - Sale-date price calculation JavaScript logic
3. None of the Python files (`app.py`), SQL, migrations, form field names/ids/actions, CSRF tokens, routes, or permission logic were modified.
4. All visual/CSS changes follow the existing design-system tokens (DM Sans, slate/brand/emerald color palette, dark mode with `.dark` class, rounded-xl inputs, pill buttons, etc.) as established in S1-UIX-01 design system and S2 states spec.