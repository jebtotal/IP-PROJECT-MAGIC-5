# S1-UIX-04 — Hi-fi Mockups and Developer Handoff

These pages are static design-review artifacts, not application code. They use shared Tailwind configuration and theme CSS, reference the extracted logo file, and contain no authentication, routing, or storage logic. The only inline JavaScript is the light/dark theme toggle.

## Shared files and conventions

| File | Purpose |
|---|---|
| `docs/ui-ux/mockups/shared/tailwind-config.js` | Tailwind CDN extension copied from the reference head: class-based dark mode, DM Sans stack, and the remapped `brand`, `indigo`, `sky`, and `slate` colors. |
| `docs/ui-ux/mockups/shared/theme.css` | Reference CSS variables and reusable `body`, `.glass-panel`, `.glow-hover`, `.modal-overlay`, scrollbar, logo-image, and pill-button rules. The PNG URL replaces the source's embedded data URI. |
| `docs/ui-ux/assets/pentad-logo.png` | PNG decoded from the reference `.pentad-logo` data URI. HTML does not include base64 logo data. |

Mockups load Tailwind CSS, Google Fonts DM Sans, and Font Awesome 6.5.1 from the same CDNs as the reference; they load the shared local config, stylesheet, and logo. Theme variables are centralized in `theme.css`; the Tailwind color/font extension is centralized in `tailwind-config.js`. Initial mode is dark, matching the reference's root `<html class="dark">`; the theme toggle switches the root class for visual review.

## Per-screen handoff

### Login — `docs/ui-ux/mockups/s1/login.html`

- **Components:** PentadERP wordmark, theme toggle, centered `max-w-md` sign-in panel, heading, email input, password input with show/hide affordance, primary Sign In button, Register link, and a Proposed Forgot password link. Demo role-login and Google sign-in controls are omitted.
- **States:** Default filled/empty form appearance is represented. Hover styling is present on controls via reference classes. Inputs have the reference brand focus ring. No error state is rendered in this static page; the source has an empty hidden `#loginError` container. Disabled styling/state is not implemented in the reference or mockup.
- **Responsive:** Main content is centered with `px-4 py-10`; the max-width panel shrinks to available viewport width. The source form’s field stack is retained.
- **Dark mode:** Starts dark and switches theme variables and `dark:` utilities using the shared toggle. Inputs use paired light/dark surface, border, and text classes.
- **Design-system classes/tokens:** `font-sans`, `glass-panel`, `rounded-3xl`, `max-w-md`, `p-8`, label `text-[10px] uppercase tracking-wider`, input `rounded-xl`/`px-4 py-2.5`, `focus:ring-2 focus:ring-brand-500`, primary `brand-600` with `brand-500` hover, and DM Sans.
- **Interactions to implement:** Authenticate on submit, show server/validation errors, implement password visibility, close/back navigation, Register navigation, and the proposed Reset navigation. The mockup buttons are inert except for theme toggle.
- **Role/right visibility:** Unauthenticated visitor. No role-specific actions appear.
- **Accessibility:** Email/password labels use matching `for`/`id`; both fields are required. The close and theme icon buttons have accessible names; decorative icons are hidden from assistive technology. Password toggle has `aria-label="Show password"`; implementation must update it to “Hide password” when visible and keep focus order adjacent to the field. Forgot password link is visibly tagged Proposed.

### Register — `docs/ui-ux/mockups/s1/register.html`

- **Components:** PentadERP wordmark, theme toggle, centered account panel, first/last-name two-column row, email input, Submit Registration button, and Sign In link. No password field appears in the registration form. A separate Proposed first-login password setup preview is included below it.
- **States:** Default, reference hover, and brand focus-ring utility states are represented. Registration-specific error/success display is not rendered; disabled state is not defined. The proposed password fields show the same default/focus treatment but no validation state.
- **Responsive:** Two name fields use the reference `grid grid-cols-2 gap-3`; both panels are `max-w-md` and padded for narrow viewports. The proposed password setup preview stacks vertically.
- **Dark mode:** Shared root theme toggle and paired field/surface `dark:` classes.
- **Design-system classes/tokens:** `glass-panel`, `rounded-3xl`, `max-w-md`, `p-8`, `grid-cols-2`, small uppercase labels, `rounded-xl` inputs, brand focus ring, primary brand button, DM Sans.
- **Interactions to implement:** Required-field/email validation, create a pending User account, show confirmation, and navigate to Sign In. The separate proposed first-login preview needs password/confirmation matching, visibility toggles, and a set-password action after approval. No form logic is included in the mockup.
- **Role/right visibility:** Public registration; submitted account is pending per the reference handler. The proposed password setup is for an approved account at first sign-in.
- **Accessibility:** Each input has a matching explicit label and `required`; the close and theme buttons have accessible names; heading is the section label. Proposed password-toggle buttons have accessible names and should announce updated show/hide state. Keyboard order follows the registration form, then the separate proposed preview.

### Main page — `docs/ui-ux/mockups/s1/main-page.html`

- **Components:** Three static role variants—Superadmin, Admin, and User with limited module View rights—each showing a sidebar/navigation sample, page title, role badge, welcome banner, four stat cards, revenue chart area, and Quick Navigation. Sidebar includes the `.pentad-logo` image. Only the theme toggle is interactive.
- **States:** Active Dashboard nav and default card states are shown. Reference hover classes remain on navigation/cards/shortcuts. Theme button has a focusable native button target; no custom `focus-visible` treatment is present in the reference. Error/disabled dashboard states are not present in the source.
- **Responsive:** Reference `sm:grid-cols-2 lg:grid-cols-4` stats and `lg:grid-cols-3` chart/quick-nav layout are used. The Superadmin frame includes the desktop `w-72` sidebar; the static page stacks all role variants vertically for review. The mobile sidebar toggle is not interactive in this artifact.
- **Dark mode:** Starts dark; shared theme button switches root class. Cards, surfaces, text, borders, role badge, and app shell use paired `dark:` classes.
- **Design-system classes/tokens:** `slate-950` sidebar, `glass-panel`, `rounded-3xl`, `p-6`/`p-7`, `bg-gradient-to-r from-brand-700 to-indigo-600`, stat-card text hierarchy, `sm`/`lg` grids, `brand`/remapped gradients, and DM Sans.
- **Interactions to implement:** Role-aware sidebar construction, page navigation, responsive sidebar open/close, chart rendering, Quick Navigation shortcuts, logout, and theme persistence. Only theme switching is implemented in the mockup.
- **Role/right visibility:** Superadmin and Admin see all module links and User Management in the reference. The limited-rights User example has Customer and Sales View access, so other module nav links are hidden. The Quick Navigation shortcuts for this User are filtered with a visible Proposed marker because the current source renders all module shortcuts regardless of View right. Admin visibility restrictions in User Management are separately marked proposed in its screen.
- **Accessibility:** Sidebar nav uses an accessible label; current nav item uses `aria-current="page"`; theme button has an accessible name; logo has alternative text; decorative icons are `aria-hidden`. Ensure implemented mobile nav exposes state and focus when opened; keyboard focus management is not shown in this static artifact.
- **Chart note:** The chart region is a static placeholder, not a canvas rendering. The source draws the chart in inline JavaScript with hard-coded colors/font, while mockups prohibit application/chart logic. Replace the placeholder with the intended chart implementation during application development, accounting for the source inconsistency recorded below.

### User Management — `docs/ui-ux/mockups/s1/user-management.html`

- **Components:** Static Superadmin list, proposed restricted Admin list, table role/status pills, Add User button, Rights Matrix/Edit actions, Proposed Block/Unblock/Approve/Designate Admin actions, and an inline Add/Edit dialog component preview.
- **States:** Active, pending, and blocked rows are shown. Reference hover utility classes are present on controls; inputs show the brand focus ring. No user-list error/empty state or disabled-action treatment is rendered.
- **Responsive:** Both lists use the reference `overflow-x-auto` border/rounded table wrapper. Name/email/actions may require horizontal scrolling at narrow widths. The dialog specimen is `max-w-md` and width constrained; the grid uses two columns as in the source.
- **Dark mode:** Shared theme toggle in the header and paired light/dark classes on shell, cards, tables, pills, and dialog fields.
- **Design-system classes/tokens:** `glass-panel`, `rounded-3xl`, `p-6`, table `text-xs`, uppercase headers, `p-4` cells, `divide-y`, `overflow-x-auto`, role/status badge treatments, input styles, and primary/outline/soft action classes.
- **Interactions to implement:** Load and filter accounts; Add/Edit forms; save/cancel; open Rights dialog; implement Block/Unblock, Approve, and Designate Admin confirmations and status transitions. Proposed controls are mockup-only and inert.
- **Role/right visibility:** Reference shows Rights Matrix only on rows whose role is exactly `user`; Edit is shown on all rows, and Add User is available in the screen. Superadmin table includes all sample roles. Admin table hides Superadmin and contains User rows only, marked Proposed; the reference renderer currently does not enforce that restriction. Users do not see the User Management navigation item.
- **Accessibility:** Tables have captions and scoped column headers. Every dialog-preview field has a label; role/status selects are keyboard operable. Proposed controls include text “Proposed” rather than relying on color alone. Add confirmation, row-specific action names, dialog semantics, focus trap/restore, and announcement of status changes when implementing.
- **Dialog specimen:** The Add/Edit form is intentionally displayed inline below the list so both the list and dialog component are visible in this static review page. It is not a live modal or a second app route.

### Rights dialog — `docs/ui-ux/mockups/s1/rights-dialog.html`

- **Components:** Centered `max-w-2xl` Rights dialog, close icon, user-specific heading, proposed All/None buttons, scrollable Customer/Product/HR/Sales/Reports groups, existing View/action checkboxes, proposed rights, proposed last-Superadmin guard message, Save Matrix, and Cancel.
- **States:** Static checked/unchecked sample values demonstrate the default state. Hover utilities are present on buttons; checkbox native focus is retained. No validation/error/disabled state is implemented.
- **Responsive:** Dialog width is constrained to `max-w-2xl` with `p-4` outer space; inner rights list is `max-h-80 overflow-y-auto`; group checkboxes use the reference two-column grid.
- **Dark mode:** Root theme toggle is not included inside the modal, matching the dialog itself; inherited root class and shared CSS provide dark surfaces/text/borders. Theme may be toggled from the surrounding application shell when integrated.
- **Design-system classes/tokens:** `modal-content`, `glass-panel`, `rounded-3xl`, `p-8`, `max-w-2xl`, `max-h-80`, `overflow-y-auto`, `space-y-4`, `rounded-2xl` groups, native checkboxes, neutral borders, and primary/outline footer buttons.
- **Interactions to implement:** Load current permissions; checkbox updates; All/None operations; save/cancel; enforce the final-Superadmin guard. All/None and guard are proposed and inert.
- **Role/right visibility:** The reference list provides Rights Matrix only for User accounts. Admin rights-editor access is proposed only for User accounts under the proposed Admin restriction; Superadmin can manage User permissions. Do not expose this editor for Admin/Superadmin target rows unless product rules change.
- **Accessibility:** Dialog has `role="dialog"`, `aria-modal="true"`, and an associated heading. Close button has an accessible name, icons are hidden, and checkbox text is explicitly associated by wrapping labels. Implement focus trap and return focus to the invoking Rights Matrix button; announce guard and save/error messages.

## Proposed items in these mockups

- Forgot password link on Login.
- Permission-filtered Quick Navigation in the limited-rights User dashboard.
- Admin User Management restriction that hides Superadmin accounts and limits management to Users.
- Block/Unblock, Approve pending user, and Designate Admin controls.
- Rights All/None controls and last-Superadmin guard message.
- Report-specific, Sale Detail, and View Job History rights visible in the Rights dialog.
- First-login password setup preview beneath the registration panel.

Each proposed UI element is visibly tagged “Proposed.” The first-login set-password preview is included in `register.html` because this task does not list a separate set-password file; it is a separate preview, not part of registration. The proposed reset-token/new-password screen is not included because there is no reset mockup file in this task's file list.

## Gaps & Assumptions

- **Brand naming inconsistency:** The reference UI is branded PentadERP, while the project/tracker is HOPE, Inc. This handoff and mockups retain “PentadERP” as explicitly required. Reference storage keys also mix prefixes, including `hope_` (for example `hope_customers_v5`) and `pentad_` (`pentad_erp_users_v6`); the mockups do not use storage.
- The expected `Private-Design-Reference` folder was unavailable in the workspace. The exact-named `PentadERP_index (FINAL).html` was available at `reference_html/PentadERP_index (FINAL).html` and was treated as the read-only source.
- Tailwind color/font configuration is kept in `tailwind-config.js`; CSS custom properties and reusable CSS are centralized in `theme.css` rather than duplicated between files.
- The static mockups omit auth, routing, persistence, real form submission, actual dialog opening, and data fetching. Only theme toggling is implemented inline. CDN resources require network access during review.
- “Forgot password?”, restricted Admin User Management, Quick Navigation rights filtering, Block/Unblock/Approve/Designate Admin, All/None, proposed granular rights, the last-Superadmin guard, and first-login password setup are not implemented in the reference and are labeled Proposed in the artifacts.
- The reference permission catalogue contains 23 rights while the Sprint plan specifies 36. These mockups show the seven task-grounded proposed additions (two report-specific rights, four Sale Detail rights, and View Job History); the remaining six are unspecified and not invented.
- The reference revenue chart uses hard-coded `#6366f1`/`#4338ca` bars, `#1e293b`/`#e2e8f0` grid lines, and `#64748b`/`#94a3b8` labels with `Plus Jakarta Sans`, which is not loaded. The dashboard mockup uses a static placeholder rather than reproducing the chart's inline JavaScript.
- The existing reference `.glass-panel` itself is not blurred; the modal overlay is. All listed UI pages use the shared stylesheet and local logo asset; the HTML does not duplicate or embed the base64 data.
