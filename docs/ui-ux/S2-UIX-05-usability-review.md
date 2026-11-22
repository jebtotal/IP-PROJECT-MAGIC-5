# S2-UIX-05 — Usability Review of Sprint 2 Screens

## Scope and method

Reviewed the Flask templates, CSS, browser-side handlers, and relevant routes in `my-web-app/`, then compared them with `docs/ui-ux/mockups/s2/`, the S2 states spec (`S2-UIX-04-states-spec.md`), and the S1 design system document (`S1-UIX-01-design-system.md`). Application files were read-only.

## Overall observations

- The Sprint 2 handoff mockups (`docs/ui-ux/mockups/s2/`) provide high-fidelity designs for Customer list, Customer form, Product list/product form/price history/price form (marked not built yet), and reusable empty/error/confirm-delete states (`states.html`).
- The built app implements **Price History** as a complete screen with its own template (`price_history.html`) and uses the generic `record_list.html` scaffold for Customers and Products.
- The **Product** module is marked "Not built yet" in the built app; a static mockup exists in S2 but no working template.
- The **design system** (S1-UIX-01) specifies DM Sans, warm stone/slate colors (`slate-`, `brand-`, `emerald-`, `amber-`, `red-` scales), pill buttons (`button { border-radius: 9999px !important }`), rounded-xl/rounded-2xl/rounded-3xl inputs, focus rings (`focus:ring-2 focus:ring-brand-500`), and paired light/dark treatments via Tailwind `darkMode: class`.
- The built app styles use a **separate palette** (slate-950, gray-200, brand-600 gradient) without DM Sans import, without the design-system color tokens, and without dark-mode `dark:` variant pairing on most components. This mirrors the S1 observations.
- ## Screen-by-screen review

### 1. Customer list

**Built screen:** Uses the generic `record_list.html` scaffold with customer module config. Renders a management panel with search, Add Customer button (hidden), status tabs (Active/Inactive/All — visible only when `is_admin`), and a table with columns: Customer No, Customer Name, Address, Payment Terms, Status, Stamp, Actions. Table rows are populated via JavaScript.

**Mockup S2 (`mockups/s2/customer-list.html`):** Full dark-mode design with `.dark` class on `<html>`. Uses DM Sans, design-system color tokens (`slate-950`, `brand-600`, `emerald-500`, `bg-white/80`/`dark:bg-slate-900/80`, etc.). Sidebar always visible on `lg`, hidden below. Header has role badge, theme toggle, module pill. Status tabs always visible with count pill. Table has the same columns; Status shown as colored pill (emerald-500/10 background with emerald-500 text for Active). Stamp shown as `—` placeholder. Add Customer button visible. Action buttons (Edit, Delete) shown in right column with proper styling. Table wrapped in `overflow-x-auto`. Responsive: sidebar hides below `lg`, main content pads at `sm`/`lg`, table scrolls horizontally.

**Matches:**
- Table structure (columns) is consistent: Customer No, Name, Address, Payment Terms, Status, Stamp, Actions.
- Status badge concept (colored pill) matches the design system's emerald-500 for active.
- Stamp shown as `—` when no value, matching the handoff note.
- Table wrapped in `overflow-x-auto` for horizontal scrolling.
- Glass-panel card for the management panel.
- Search field with magnifying glass icon and sr-only label.
- Add Customer button primary style (brand-600 bg-white shadow).
- Role badge and theme toggle in header.

**Deviations / usability issues:**
- **Design system not applied:** Built app has no DM Sans font import; global stylesheet uses separate slate/blue palette, smaller radii, and basic spacing. No `tailwind-config.js` or `theme.css` inclusion. Contrast and focus ring differ from design system specs.
- **Dark mode absent:** Built app has no `dark:` utility pairing; the root `<html>` has no `.dark` class toggling. Mockup shows paired light/dark treatments for surfaces, borders, text, and inputs.
- **Add button visibility:** Built app has `<button hidden>` by default; mockup always shows Add Customer. The built button is conditional on `is_admin` config but always hidden in the static template.
- **Status tabs:** Built app shows tabs only when `is_admin`; mockup shows Active/Inactive/All tabs always visible with counts. Non-admin users should not see these tabs per the guide facts (User sees active rows only: no Active/Inactive/All tabs).
- **Stamp column:** Built app includes a Stamp column header; mockup shows Stamp as `—` for sample data. The built app's stamp content is populated dynamically via JavaScript.
- **Right visibility:** Mockup represents an authorized Admin/Superadmin view; each action (Add, Edit, Delete) must only appear with its matching right. The built screen's action buttons are placeholders — their presence/absence by right is not wired in the static template.
- **Header difference:** Built app's index.html has a simpler header without the module pill, role badge, or theme toggle seen in the mockup.
- ### 2. Products list

**Built screen:** The Products module is **not built yet**. The app returns a "Not built yet" status with a static marker. No product list template is rendered; users see a coming-soon state.

**Mockup S2 (`mockups/s2/product-list.html`):** Marked "Not built yet" in the file itself, but provides a static high-fidelity mockup. Uses the shared dark theme, DM Sans, design-system colors. Has the full table layout: Prod Code, Description, Unit, Current Price, Status, Stamp, Prices/Actions. Status shown as emerald-500/10 pill for Active. Stamp shown as `—`. Add Product button visible. Action buttons (Edit, Delete) in right column. Status/Stamp columns marked **Proposed** where not in the product reference. Restore labeled Proposed for inactive rows. A note: "$13.75 is shown as supplied; its effective date was not provided."

**Matches (in the mockup only — not in the built app):**
- Table column layout: Prod Code, Description, Unit, Current Price, Status, Stamp, Prices/Actions.
- Status pill styling (emerald-500/10 for Active).
- Stamp as `—` placeholder.
- Add Product primary button.
- Status/Stamp columns marked Proposed where product reference data is absent.

**Deviations / usability issues:**
- **Not built yet:** The product screen has no working template in the built app. The mockup is static only; no backend routes, no JavaScript data loading, no form handling.
- **Status/Stamp Proposed:** The mockup marks Status and Stamp columns as **Proposed** where they are not in the product reference. The built app does not have these columns at all.
- **Restore for inactive rows:** Mockup labels Restore as Proposed for inactive rows; the built app has no inactive/Restore functionality for products.
- **Price Logs right:** Mockup shows a Price Logs button and Edit/Delete buttons; these require respective rights (Price History View/Edit/Add/Delete) that are not wired.

**Status:** Not built yet — mark accordingly. No screen-specific usability findings can be inferred for the built app since the screen does not exist.

### 3. Price History

**Built screen:** Has a complete template (`price_history.html`) with full implementation. Shows product code, description, unit. Admin (`is_admin`) sees status tabs (Active/Inactive/All) with count spans. Table has columns: Effective Date, Unit Price, Status, Stamp, Actions. Non-admin view hides Status and Stamp columns. Add price button is hidden (admin only). JavaScript config passes `productCode`, `productName`, `productUnit`, `isAdmin`. Dialog for adding price with Effective Date (date type) and Unit Price (number input with min/max/step). Current price helper with sale date input: applicable price displayed below the input. Script sets `window.priceHistoryConfig` with product info.

**Mockup S2 (`mockups/s2/price-history.html`):** Marked "Not built yet" in the file itself, but provides a static high-fidelity mockup. Uses shared dark theme, DM Sans, design-system colors. Has price log table: Effective Date, Unit Price, Status, Stamp Log, Actions. Status shown as amber-500/10 Undetermined (since no effective date supplied in the sample). Current price helper with sale date input — applicable price shown as `— · effective date needed`. Edit button proposed (labeled "Edit" with small status marker "Proposed"); Delete button present. Sale date input with class `rounded-xl border-gray-200 bg-white/50 px-4 py-2.5 text-xs ... focus:ring-2 focus:ring-brand-500 dark:border-gray-800 dark:bg-slate-950/50 dark:text-white`. Note: "Use the latest active price effective on or before the sale date. The supplied $13.75 sample has no effective date, so it cannot be selected here." Reference displays Active for non-deleted rows and `—` in Stamp Log. Edit and Current/Future/Past status interpretation are Proposed.

**Matches:**
- Table structure: Effective Date, Unit Price, Status, Stamp Log, Actions.
- Current price helper with sale date input and "Applicable unit price" display.
- Sale date input with design-system styling (rounded-xl, focus ring brand-500, dark mode variants).
- Add Price primary button.
- Status styling: Undetermined badge (amber-500/10 with amber-500 text) when no effective date — matches the proposed status interpretation.
- Stamp Log shown as `—` when no value.
- Reference displays Active for non-deleted rows and `—` in Stamp Log.
- Price form dialog: Effective Date (date input), Unit Price (number input), Cancel/Add actions.

**Deviations / usability issues:**
- **Design system not fully applied:** Built app has no DM Sans font import in the template; the price-history.html extends base.html and may not include the DM Sans stylesheet. Global stylesheet uses separate palette. Focus ring (`focus:ring-2 focus:ring-brand-500`) uses `brand-500` which is the design-system emerald accent — class usage is correct but the font is missing.
- **Dark mode pairing:** Most `dark:` variants are present on inputs and surfaces (e.g., `dark:bg-slate-950/50`, `dark:text-white`), but the overall template lacks the `.dark` root class toggle and some border/dark surface pairings are inconsistent.
- **Status tabs only for admin:** Built app correctly shows tabs only when `is_admin`; mockup shows tabs always. This aligns with the guide facts: User sees active rows only; no Active/Inactive/All tabs for User.
- **Status/Stamp columns hidden for non-admin:** Built app correctly hides Status and Stamp columns when not admin — this matches the guide facts and the mockup's proposed behavior.
- **Stamp wording:** Mockup shows "Stamp Log" as column header; built app shows "Stamp". Terminology difference but both convey the same concept (creation/modification audit stamp).
- **Effective date/helper:** The sale-date helper in the mockup is more fully specified (proposed rule: choose the latest active effective price on or before the sale date). The built app has the helper UI but the JavaScript logic for price calculation is not in the static template.
- **Edit button:** Mockup has Edit as **Proposed** with a small "Proposed" status marker; the built app has an Add price dialog but no Edit workflow visible in the template (edit would require Price History Edit right and is marked Proposed in the handoff notes).
- **Delete right:** Delete button present in both; in the built app, Delete requires the Price History Delete right. The mockup does not enforce rights but marks Delete as present.
- ## FIX LIST table

| ID | Screen | Issue | Severity | Fix | Owner |
|----|---|---|---|---|---|
| S2UX05-01 | Customer list | Design system not applied: no DM Sans font, separate palette instead of brand/slate/emerald/amber/red tokens, no pill buttons, no dark mode | High | Apply design-system tokens (DM Sans import, `tailwind-config.js`, `theme.css` or equivalent), pair all `dark:` variants, make buttons pill-shaped via `button { border-radius: 9999px !important }`, add dark theme toggle | UI |
| S2UX05-02 | Customer list | Status tabs visible only when `is_admin`; non-admin users should see active rows only with no Active/Inactive/All tabs per guide facts | Medium | Ensure tabs (`record-tabs`) are conditionally rendered: show only for admin/superadmin; for user role, omit tabs entirely and show active records without tab filter | Developer |
| S2UX05-03 | Customer list | Add button hidden by default (`hidden` attribute); mockup shows Add Customer always visible; need right-gated visibility | Medium | Show Add button only when the user has the Create right for the module; hide otherwise. Remove `hidden` attribute and replace with right-check logic. | Developer |
| S2UX05-04 | Customer list | Right visibility not wired: Action buttons (Edit, Delete) should only appear with matching rights (Customer Edit, Customer Delete). Mockup represents Admin/Superadmin view. | Medium | Implement right-gated action buttons: each action button conditionally rendered based on the user's module-specific rights. | Developer |
| S2UX05-05 | Products list | Product screen not built yet: no working template, no backend routes, no JavaScript data loading. Mockup is static only. | Critical | Build the Product list screen per S2 mockup design, implement backend routes and data loading, wire rights-gated actions. | Developer |
| S2UX05-06 | Price History | Design system not fully applied: DM Sans not imported, some `dark:` variants inconsistent, missing overall dark root toggle. | Medium | Import DM Sans font, ensure all component `dark:` variants are paired correctly, add `.dark` class toggling on root element or theme context. | UI |
| S2UX05-07 | Price History | Edit workflow not implemented: Add Price dialog present but no Edit path; marked Proposed in handoff. No Price History Edit right or form for editing existing prices. | Low | Implement Price History Edit right and edit dialog (reuse add-price form components with pre-filled values), or explicitly mark as future scope. | Developer |
| S2UX05-08 | Price History | Stamp wording difference: column header "Stamp" in built app vs "Stamp Log" in mockup. Minor inconsistency. | Low | Harmonize terminology: use "Stamp Log" as the column header to match the mockup/reference, or update mockup caption to "Stamp". | UI |
| S2UX05-09 | Price History | Sale-date helper UI present but price calculation logic not in static template. | Low | Implement JavaScript logic for "latest active effective price on or before sale date" or document as future backend calculation. | Developer | 
 E C H O   i s   o n .  
 
- **Delete right:** Delete button present in both; in the built app, Delete requires the Price History Delete right. The mockup does not enforce rights but marks Delete as present.
- **S1UX05-03 (All screens):** The app continues to use a separate palette/type/shape system without DM Sans or dark mode. This carries into Sprint 2; the fix from Sprint 1 (apply shared design tokens consistently) is a prerequisite for S2 fixes. **Owner: Developer** (carry forward to Sprint 2 backlog).
- **S1UX05-05 (Reset / Set password):** Successful reset/set responses still redirect without displaying the success message on the destination page. This is a general pattern that affects multiple screens; the S2 price history add dialog similarly redirects without on-screen success confirmation after saving a price. **Owner: Developer** (investigate consistent pattern).
- **S1UX05-06 (Main page):** The built workspace omits the mockup's role badge, welcome banner, stat cards, chart, and Quick Navigation; module tiles use fragments without destinations. While out of scope for S2 (different module area), this confirms the team's awareness of design-system alignment gaps that also impact S2 screens. **Owner: Developer** (track alongside S2 work).
- **S1UX05-01 (Register / Login):** Registration claims approval although the form says approval is pending; pending status also has no distinct login outcome. Align the API success message and login gating/feedback with the actual approval state. This auth-flow issue is foundational; ensure S2 module screens do not repeat the same pending-account confusion. **Owner: Developer**.
- PR TITLE: S2-UIX-05: Usability Review of Sprint 2 Screens
- PR DESCRIPTION:
  - Created S2-UIX-05-usability-review.md with screen-by-screen comparison of Customers, Products, and Price History between built app templates and S2 mockups
  - Identified 9 usability issues across 3 screens: design system not applied, product screen not built, status tabs visibility, add button gating, right visibility, dark mode gaps, edit workflow missing, stamp terminology, and helper logic
  - Fixed list table with ID, screen, issue, severity, fix, and owner (UI/Developer) for developer implementation
  - Added Sprint 1 fix list follow-up carrying forward 4 relevant S1UX issues (S1UX05-03, S1UX05-05, S1UX05-06, S1UX05-01) as carry-over items for the team
  - Design system token application (DM Sans, color palette, dark mode, pill buttons) is the top priority across all screens