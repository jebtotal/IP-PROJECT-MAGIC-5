## Gaps & Assumptions

- `Private-Design-Reference` folder unavailable; `reference_html/PentadERP_index (FINAL).html` used as source
- Tailwind config in `tailwind-config.js`; CSS in `theme.css`; no duplication between files
- Mockups omit auth, routing, persistence, real form submission, actual dialog opening, data fetching. Only theme toggling inline. CDNs need network access.
- "Coming soon" state uses `opacity-50`/`dark:opacity-50`, `not-allowed` caption with `text-[10px] font-bold uppercase tracking-wider` / `gray-400`/`dark:gray-500`
- Superadmin-only Audit viewer separate screen with per-report rights and Print/Save as PDF
- Soft delete with confirm follows S1-UIX-04 confirm-modal pattern
- All new components follow the existing design-system tokens: DM Sans typography, remapped Tailwind palette (`brand` = emerald, `indigo` = terracotta, `sky` = warm orange, `slate` = warm stone/charcoal), paired light/dark treatments using `.dark` class on `<html>`, and consistent spacing/radii from the reference
### Job History Form — `docs/ui-ux/mockups/s3/job-history-form.html`

- **Components:** Centered modal `max-w-2xl` with job history table, Add Job Entry button, table with columns Job Code/Title/Department/Hire Date/Separation Date/Status/Stamp. Add Entry form with fields: Job Title, Department, Hire Date, Separation Date, Status. Save/Cancel buttons
- **States (Empty state):** "No job history entries found." message when employee has no job history
- **States (With entries):** Table shows job history with stamp information
- **Right visibility:** Add Entry button and form visible to Superadmin/Admin only; hidden from User. "No right" state: form hidden or ghosted placeholder.
- **Responsive:** Modal centered `max-w-2xl` with `p-8`; form fields stack vertically on narrow viewports.
- **Dark mode:** Starts dark; switches via shared toggle. Form fields have paired light/dark surface, border, text classes.
- **Accessibility:** Form fields have matching explicit labels and `required` where applicable. Close button has accessible name. Decorative icons hidden from assistive tech. Logical focus order.
- **Proposed tags:** `[P]` markers.
- **Sample data:** E-001 Maria Santos job history: J-001 Software Engineer (2021-06-15 to present), previously J-002 Product Designer (2022-01-15 to 2022-08-20)
### Employee Profile — `docs/ui-ux/mockups/s3/employee-profile.html`

- **Components:** Header with employee photo/avatar (E-001 Maria Santos), name, role, department; two-pane layout with tab navigation Overview | Job History; job history table with Code/Title/Department/Hire Date/Separation Date/Status/Stamp
- **States (Overview mode):** Basic info, hire date, employment status. Job History tab hidden/disabled without View Job History right.
- **States (Job History mode):** Full job history table visible when right is present. Without right, tab is hidden/ghosted with note about Data Privacy Act RA 10173.
- **Right visibility / Data Privacy Act RA 10173:** Job History tab visible only with right; otherwise hidden with proposed notice. Salary field hidden without right; shown masked/greyed with notice when right present. Separation date distinct from "deleted" status.
- **Dark mode:** Paired `dark:` classes on all surfaces, text, interactive elements. Overview and job history adapt to dark mode.
- **Accessibility:** Employee photo has alt text/aria-label. Tab navigation keyboard operable. Job history table has caption and scoped column headers. Action elements have accessible names.
- **Responsive:** Two-pane layout stacks vertically on narrow screens (max-w-2xl, full-width). Job history table becomes horizontally scrollable.
- **Proposed tags:** `[P]` markers.
- **Sample data:** E-001 Maria Santos, Software Engineer, Department: Engineering, Hire Date: 2021-06-15, Job History: J-001 Software Engineer (2021-06-15), J-002 Product Designer (2023-01-20)
### Employee Form — `docs/ui-ux/mockups/s3/employee-form.html`

- **Components:** Centered `max-w-2xl` glass-panel modal with form fields, PentadERP wordmark, theme toggle, role badge, First Name, Last Name, Email, Department dropdown, Role dropdown, Hire Date date picker, Separation Date date picker (conditional), Salary input (hidden without View Job History right), Job History textarea (hidden without that right), Save/Cancel buttons
- **States (Add mode):** Form title "Add Employee Account"
- **States (Edit mode):** Form title "Edit Employee Account" pre-filled with E-001 Maria Santos
- **Right visibility / Data Privacy:** Salary hidden without View Job History right; Job History hidden without that right. Separation Date shown only for employees who left; distinct from "deleted" status.
- **Responsive:** Fields stack vertically on narrow viewports; form centered.
- **Dark mode:** Starts dark; switches via shared toggle. Inputs have paired light/dark surface, border, text. Salary/Job History have `dark:` variants.
- **Accessibility:** Each input has matching explicit label and `required` where applicable. Close and theme buttons have accessible names. Decorative icons hidden from assistive tech. Logical focus order.
- **Proposed tags:** `[P]` markers.
- **Sample data:** E-001 Maria Santos, First Name: Maria, Last Name: Santos, Role: Software Engineer, Department: Engineering, Hire Date: 2021-06-15, Separation Date: (current employee), Salary: $75,000
### Employee List — `docs/ui-ux/mockups/s3/employee-list.html`

- **Components:** Page header with role badge, employee table with Employee No./Name/Role/Department, Add Employee button, toolbar with tab navigation
- **States (Superadmin/Admin):** All employees with tabs (Active/Inactive/All) showing counts, Status badge, Stamp (CREATED/EDITED/DELETED/RESTORED + user + datetime), Restore on deleted rows (shaded). Delete = soft delete with confirm.
- **States (User):** Active rows only. No tabs. No Status or Stamp columns.
- **Data Privacy Act RA 10173:** Salary and job history hidden unless "View Job History" right is present.
- **Right visibility:** Add Employee button visible to Superadmin/Admin only; Employee actions hidden from User. "View Job History" toggle visible only with right. "No right" state: column hidden or ghosted.
- **Responsive:** Table wraps via `overflow-x-auto`.
- **Dark mode:** Paired `dark:` classes; status badges invert in dark mode.
- **Accessibility:** Table has caption; action buttons have accessible names; focus visible.
- **Proposed tags:** `[P]` markers.
- **Sample data:** E-001 Maria Santos, J-001 Software Engineer, D-001 Engineering
### Job List — `docs/ui-ux/mockups/s3/job-list.html`

- **Components:** Page header with role badge, job table with Code/Title/Department/Actions, Add Job button, toolbar with tab navigation (Superadmin sees all tabs; User sees only Active)
- **States (Superadmin/Admin):** All jobs with tabs (Active/Inactive/All) showing counts, Status badge, Stamp (CREATED/EDITED/DELETED/RESTORED + user + datetime), Restore on deleted rows (shaded). Delete = soft delete with confirm.
- **States (User):** Active rows only. No tabs. No Status/Stamp columns. No action buttons.
- **Right visibility:** Add Job button visible to Superadmin/Admin only; Job actions hidden from User. "No right" state: column hidden or ghosted.
- **Responsive:** Table wraps via `overflow-x-auto`.
- **Dark mode:** Paired `dark:` classes; status badges invert in dark mode.
- **Accessibility:** Table has caption; action buttons have accessible names; focus visible.
- **Proposed tags:** `[P]` markers.
- **Sample data:** J-001 Software Engineer, J-002 Product Designer
## Per-screen handoff

### Department List — `docs/ui-ux/mockups/s3/department-list.html`

- **Components:** Page header with role badge, department table with Name/Description/Actions, Add Department button, toolbar with tab navigation (Superadmin sees all tabs; User sees only Active)
- **States (Superadmin/Admin):** All departments with tabs (Active/Inactive/All) showing counts, Status badge column, Stamp column (CREATED/EDITED/DELETED/RESTORED + user + datetime), Restore button on deleted rows (shaded). Delete = soft delete with confirm.
- **States (User):** Active rows only. No tabs. No Status or Stamp columns. No action buttons (rights missing).
- **Right visibility:** Add Department button visible to Superadmin/Admin only; Department actions hidden from User. "No right" state: action column hidden or ghosted placeholder.
- **Responsive:** Table wraps via `overflow-x-auto` on narrow screens.
- **Dark mode:** Paired `dark:` classes on all surfaces, tables, buttons, text. Status badges invert in dark mode.
- **Accessibility:** Table has caption; action buttons have accessible names; focus visible on interactive elements.
- **Proposed tags:** `[P]` markers for elements not in reference.
- **Sample data:** D-001 Engineering, D-002 Marketing
# S3-UIX-04 — Employee Directory and Department/Job Mockups

Static mockups for Employee, Department, and Job modules. Loads shared `tailwind-config.js` and `theme.css`. No application logic or built-app changes.

## Shared files

- `docs/ui-ux/mockups/shared/tailwind-config.js` — Tailwind CDN extension, class-based dark mode, DM Sans, remapped `brand`/`indigo`/`sky`/`slate` colors
- `docs/ui-ux/mockups/shared/theme.css` — CSS variables for `body`, `.glass-panel`, `.glow-hover`, `.modal-overlay`, scrollbar, pill-button
- `docs/ui-ux/assets/pentad-logo.png` — Logo asset

## Mockup files

- `department-list.html` — Dep list: Superadmin/Admin see all rows with tabs+counts+status+stamp; User sees active rows only, no status/stamp columns. Add button and actions visible to Superadmin/Admin only.
- `job-list.html` — Job list: Same pattern. Superadmin/Admin see all jobs with status/stamp tracking; User sees active rows only.
- `employee-list.html` — Employee list: Superadmin/Admin see all employees with tabs, status badges, stamp column, restore on deleted (shaded). User sees active rows only, no status/stamp columns. Salary/job history hidden per RA 10173 without View Job History right.
- `employee-form.html` — Employee add/edit form: Centered glass-panel modal. Fields: First Name, Last Name, Email, Department, Role, Hire Date, Separation Date, Salary (conditional), Job History (conditional). Salary and Job History hidden without View Job History right.
- `employee-profile.html` — Employee profile: Photo/avatar, name, role, department. Two-pane layout with Overview/Job History tabs. Job History conditional on View Job History right. RA 10173: salary/job history hidden without the right.
- `job-history-form.html` — Job history form: Centered modal with table of job entries and stamp columns. Add Entry form with Job Title, Department, Hire Date, Separation Date, Status. Add Entry button visible to Superadmin/Admin only.

## States and right visibility

- **Supervisor/Admin views:** All rows with tab navigation (Active/Inactive/All), status badges, stamp column, restore on deleted (shaded). Delete = soft delete with confirm.
- **User views:** Active rows only. No tabs. No status/stamp columns. No action column buttons (rights missing). Salary/job history hidden per RA 10173 unless View Job History right present.
- **Right visibility:** Add buttons and action columns visible to Supervisor/Admin only; hidden from User. "No right" state: column hidden or ghosted placeholder.
- **Coming soon:** Grayed-out pill button with `opacity-50`/`dark:opacity-50` and `not-allowed` cursor for modules not yet built.

## Data Privacy Act RA 10173

- Salary and job history hidden from User role without View Job History right
- Even with the right, only employees with actual job history show that section
- Separation date distinct from deleted status

## Design system tokens

- DM Sans typography, remapped Tailwind palette (`brand` = emerald, `indigo` = terracotta, `sky` = warm orange, `slate` = warm stone/charcoal)
- Paired light/dark treatments using `.dark` class on `<html>`
- Consistent spacing, radii, and shadow patterns
- Role colors: Superadmin = amber, Admin = brand (emerald), User = emerald

## Gaps & Assumptions

- `Private-Design-Reference` folder unavailable; `reference_html/PentadERP_index (FINAL).html` used as source
- Tailwind config in `tailwind-config.js`; CSS in `theme.css`; no duplication between files
- Mockups omit auth, routing, persistence, real form submission, actual dialog opening, data fetching. Only theme toggling inline. CDNs need network access.
- "Coming soon" state uses `opacity-50`/`dark:opacity-50`, `not-allowed` caption with `text-[10px] font-bold uppercase tracking-wider` / `gray-400`/`dark:gray-500`
- Superadmin-only Audit viewer separate screen with per-report rights and Print/Save as PDF
- Soft delete with confirm follows S1-UIX-04 confirm-modal pattern
- All new components follow the existing design-system tokens
# S3-UIX-04 — Employee Directory and Department/Job Mockups

Static, illustrative handoff for the Employee, Department, and Job modules. The mockups load the shared S1/S2 design system `tailwind-config.js` and `theme.css`; they do not contain application logic or change the built app.

## Shared files and conventions

| File | Purpose |
|---|---|
| `docs/ui-ux/mockups/shared/tailwind-config.js` | Tailwind CDN extension: class-based dark mode, DM Sans stack, remapped `brand`, `indigo`, `sky`, and `slate` colors. |
| `docs/ui-ux/mockups/shared/theme.css` | CSS variables and reusable `body`, `.glass-panel`, `.glow-hover`, `.modal-overlay`, scrollbar, logo-image, and pill-button rules. |
| `docs/ui-ux/assets/pentad-logo.png` | PNG decoded from the reference `.pentad-logo` data URI. |
| `docs/ui-ux/mockups/s3/department-list.html` | Department list screen mockup |
| `docs/ui-ux/mockups/s3/job-list.html` | Job list screen mockup |
| `docs/ui-ux/mockups/s3/employee-list.html` | Employee list screen mockup |
| `docs/ui-ux/mockups/s3/employee-form.html` | Employee add/edit form mockup |
| `docs/ui-ux/mockups/s3/employee-profile.html` | Employee profile view mockup |
| `docs/ui-ux/mockups/s3/job-history-form.html` | Job history form mockup |

All mockups load Tailwind CSS, Google Fonts DM Sans, and Font Awesome 6.5.1 from the same CDNs as the reference; they load the shared local config, stylesheet, and logo. Theme variables are centralized in `theme.css`; the Tailwind color/font extension is centralized in `tailwind-config.js`. Initial mode is dark, matching the reference's root `<html class="dark">`; the theme toggle switches the root class for visual review.