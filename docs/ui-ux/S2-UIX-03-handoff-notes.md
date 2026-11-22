# S2-UIX-03 — Hi-fi mockups and handoff notes

Static, illustrative handoff for the Customer, Product, and Price History screens. The six mockups load the Sprint 1 shared `tailwind-config.js` and `theme.css`; they do not contain application logic or change the built app.

## Screens

### Customer list — built screen reference

- **File:** [mockups/s2/customer-list.html](./mockups/s2/customer-list.html)
- **Components and tokens:** Built workspace shell, module pill, rounded white record panel, search field, Active/Inactive/All tabs, compact table, status badge, and row actions. Uses DM Sans, warm stone surfaces, emerald actions/status, and the shared dark palette.
- **States:** Shows the Admin/Superadmin list with the supplied sample customer, `C-001 — Acme Corporation`. Counts are sample-only. Address, payment terms, and stamp are shown as `—` because no sample values were supplied.
- **Dark mode:** Opens in the shared dark theme; paired `dark:` utilities show the light-theme treatment when the root `dark` class is removed.
- **Responsive:** Sidebar is hidden below `lg`; main content pads at `sm`/`lg`; the wide table scrolls horizontally.
- **Right visibility:** The screenshot represents an authorized Admin/Superadmin view. Add, Edit, and Delete are examples; in the built screen each action must only appear with its matching right. Inactive rows and Restore are available to eligible administrators with Delete right.
- **Accessibility:** Main navigation has a label and current-page state; table headings use `scope`; search has a screen-reader label; icon-only controls have accessible names; status also has text.

### Customer form — built screen reference

- **File:** [mockups/s2/customer-form.html](./mockups/s2/customer-form.html)
- **Components and tokens:** Customer modal treatment, compact uppercase field labels, rounded inputs, brand focus rings, and primary/secondary actions from the reference and built form.
- **States:** Add Customer is the primary form; a separate static edit-state example shows `C-001` as read-only and the supplied name prefilled. Required fields are marked in HTML. Payment terms use the built/wireframe options `COD`, `30D`, and `45D`.
- **Dark mode:** Shared dark theme shown by default; light utilities are paired on fields and surfaces.
- **Responsive:** The modal fits the content width with page gutters; action buttons stack on narrow viewports and align in a row at `sm`.
- **Right visibility:** Add and Edit forms require the corresponding Customer Add or Customer Edit right. The sample shows a Superadmin view; controls are not permission enforcement.
- **Accessibility:** Every field has an associated label; required fields use native `required`; read-only Customer No is identified in its label; close action has an accessible name. The static form does not submit.

### Product list — not built yet

- **File:** [mockups/s2/product-list.html](./mockups/s2/product-list.html)
- **Components and tokens:** Reuses the built workspace and Customers record-list pattern. Product Code, Description, Unit, Current Price, and Price Logs follow the available reference; customer-pattern search/tabs and Status/Stamp columns are marked **Proposed** where not in the product reference.
- **States:** Marked **Not built yet**. The only product row is the requested sample `P-001 — Industrial Widget A — pcs — $13.75`. Its effective date was not supplied, so `$13.75` is sample display data and is not asserted to be the price for a particular sale date. Status/Stamp values and counts illustrate the layout only. Restore is labeled Proposed for inactive rows and is not attached to the active sample.
- **Dark mode:** Uses the shared theme tokens and paired light/dark utilities.
- **Responsive:** Sidebar hides below `lg`; the wide product table scrolls horizontally; toolbars wrap.
- **Right visibility:** Add/Edit/Delete/Price Logs follow their respective Product or Price History rights. Admin/Superadmin status filtering and proposed Restore are not shown to ordinary Users. Actual rights are not wired in this static file.
- **Accessibility:** Labeled search, status tab semantics, caption, scoped headings, text status, and named actions are included.

### Product form — not built yet

- **File:** [mockups/s2/product-form.html](./mockups/s2/product-form.html)
- **Components and tokens:** Product modal, reference field styles, required Product Code/Description/Unit Measure, and Save Product/Cancel actions.
- **States:** Add Product plus an edit-state specimen with Product Code read-only and editable values prefilled from the supplied product sample. This is a static reference-based mockup, not an available app screen.
- **Dark mode:** Uses the shared theme tokens and paired light/dark input and surface utilities.
- **Responsive:** Form fields remain single-column in the dialog; the edit-state example becomes a three-column grid at `sm`.
- **Right visibility:** Add and Edit states require Product Add and Product Edit rights, respectively.
- **Accessibility:** Labels are explicitly associated; required fields use native `required`; Product Code is read-only in the edit example; the close button is named. No app behavior is attached.

### Price history — not built yet

- **File:** [mockups/s2/price-history.html](./mockups/s2/price-history.html)
- **Components and tokens:** Reference price-log table, modal-like rounded panel, proposed sale-date helper, status chips, and shared theme palette. Price Logs title and table fields follow the reference.
- **States:** Marked **Not built yet**. Displays the supplied `P-001` / `$13.75` sample without inventing an effective date. Since no date was supplied, the status is **Undetermined** and the helper result is `—`; it cannot identify a current price. The helper is Proposed and describes the rule: choose the latest active effective price on or before the sale date. Edit and the Current/Future/Past status interpretation are Proposed; the reference displays Active for non-deleted rows and `—` in Stamp Log.
- **Dark mode:** Shared theme shown by default; table, surface, borders, and text have paired light/dark classes.
- **Responsive:** Table scrolls horizontally; helper fields stack on small viewports and form a two-column row at `sm`.
- **Right visibility:** Add Price and Delete require their matching Price History rights; Edit is Proposed and would require Price History Edit. Visibility and access are not implemented here.
- **Accessibility:** Table caption and scoped headings, labeled date input, semantic section headings, visible text labels, and named actions are included.

### Price form — not built yet

- **File:** [mockups/s2/price-form.html](./mockups/s2/price-form.html)
- **Components and tokens:** Reference Add Price form with read-only Product Code, required Effective Date and Unit Price, and Save Price/Cancel actions. Edit Price reuses these components and is marked Proposed.
- **States:** Add Price shows the supplied `$13.75` sample and leaves the date blank because the sample has no effective date. The reference defaults the date to today; this static specimen does not simulate that default. Edit Price and editing the effective date are Proposed (not in the reference).
- **Dark mode:** Uses shared dark theme by default and paired light/dark form treatments.
- **Responsive:** Add/Edit examples stack on narrow viewports and display as two columns at `xl`; actions stack then align from `sm`.
- **Right visibility:** Add requires Price History Add; proposed Edit requires Price History Edit. Product View/Price History View is needed to reach the parent history. Controls are illustrative only.
- **Accessibility:** Form labels are associated, numeric price uses decimal input semantics, required fields use native `required`, read-only Product Code is shown, and close buttons have accessible names.

## Gaps & Assumptions

- **Reference location:** The named `Private-Design-Reference` directory is not available in the workspace. The available read-only `reference_html/PentadERP_index (FINAL).html` was followed; the Sprint 1 design-system document also identifies this file as the source. It controls reference-specific labels, modal/table shapes, tokens, and the price form.
- **Student guide:** No separate Hope Inc. student guide was found in the repository or sibling project folders. The user-provided sample values and behavior statement were followed alongside the S2 wireframes and [Sprint 1 board and eight-week module plan](../scrum/SPRINT_1_BOARD_AND_8_WEEK_MODULE_PLAN.md). Exact guide wording and additional sample values remain unverified.
- **Sample disagreement:** The user-specified `C-001 Acme Corporation` and `P-001 Industrial Widget A $13.75` were used instead of the wireframe/reference examples `C0001 Acme Supplies` and `$45.00`. Customer address, payment terms, audit stamp, and price effective date were not supplied, so no values were invented.
- **Built status:** Customers is built; Product and Price History are not built yet. The built app’s `Coming soon. This module is not available yet.` state is represented with a visible **Not built yet** marker on product and price screens. These HTML files are design handoff only; they do not change app templates or behavior.
- **Proposed items:** Product search and status tabs, product Status/Stamp columns, Restore, sale-date price helper, price Edit, effective-date editing, and Current/Future/Past price display semantics are marked Proposed where they are absent from the reference. The reference’s Active status and blank Stamp Log are called out rather than silently replaced.
- **Static behavior:** Navigation, theme toggle, tabs, search, actions, and forms are visual samples only. No rights are simulated or enforced by the HTML.
