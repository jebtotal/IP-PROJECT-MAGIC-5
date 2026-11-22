# S3-UIX-05 — Usability Review of Sprint 3 Screens

## Scope and method

Reviewed the built HR templates (`my-web-app/templates/`) and compared them with `docs/ui-ux/mockups/s3/`, the S3 job timeline spec (`S3-UIX-03-job-timeline-spec.md`), the HR tabs responsive spec (`S3-UIX-03b-hr-tabs-responsive.md`), the S3 handoff notes (`S3-UIX-04-handoff-notes.md`), and the S1 design system (`S1-UIX-01-design-system.md`). Application files were read-only.

This is a **static code review**; the app was not run. The HR module is still "Coming soon" in the built app — only `employee_profile.html` exists among the HR screens; `employee_list.html` and `employee_form.html` are not built. Findings are based on the source and mockups, not a browser-rendered session.

## Overall observations

- The S3 mockups (`mockups/s3/employee-list.html`, `employee-form.html`, `employee-profile.html`, `job-timeline.html`, `job-history-form.html`) are fully built static designs with the shared S1 design system: DM Sans, remapped Tailwind colors (`brand` = emerald, `indigo` = terracotta, `sky` = warm orange, `slate` = warm stone/charcoal), `tailwind-config.js` extension, and `theme.css` variables.
- The actual `my-web-app` only has `employee_profile.html` among the HR screens. `employee_list.html` and `employee_form.html` are **not built** — they are listed as "Coming soon" with the grayed-out pill button pattern (`opacity-50`, `not-allowed`, `text-[10px] font-bold uppercase tracking-wider` / `gray-400`/`dark:gray-500`).
- The shared design system tokens are present in the mockups but **not applied** in the built `my-web-app/static/style.css`, which uses a separate palette, smaller radii, and no DM Sans import (consistent with the S1 usability review carry-over S1UX05-03).
- Dark mode is properly tokenized in the mockups via the `.dark` class on `<html>`, but the built app's `style.css` lacks the shared dark-theme variables, so contrast and color rendering will differ.
- The S3 specs correctly implement guide-fact role distinctions: User sees active rows only (no tabs, no Status/Stamp columns); Admin/Superadmin see all rows with tabs + counts + Status badge + Stamp column + Restore on deleted rows (shaded).
- Right visibility is correctly specified in the mockups: Add buttons and action columns visible to Superadmin/Admin only; hidden from User. "No right" state uses ghosted/placeholder columns.
- The job timeline correctly hides salary per RA 10173 and shows promotion/transfer icons with visible text.
- The job timeline empty state uses the `job-timeline-empty` pattern (`p-6`, muted, centered).
### Employee List (not built — "Coming soon")

The `employee-list.html` mockup shows the complete design:

- **Superadmin/Admin view**: Page header with role badge, employee table with columns Employee No./Name/Role/Department, toolbar with tab navigation (Active/Inactive/All showing counts), Status badge column, Stamp column (CREATED/EDITED/DELETED/RESTORED + user + datetime), Restore button on deleted rows (shaded background). Add Employee button visible. Salary and job history hidden unless "View Job History" right is present.
- **User view**: Active rows only. No tabs. No Status or Stamp columns. No action column buttons. Salary/job history hidden per RA 10173.
- **Search/filters**: Tab navigation serves as the filter UI (Active/Inactive/All). No keyword search pill is wired in the mockup, but the S2 pattern includes a search pill inside `.record-toolbar`.
- **Separation date**: Shown as a column value; distinct from "deleted" status per Data Privacy Act RA 10173.
- **Empty state**: Not explicitly shown in the mockup but follows the `table-message` pattern (`p-6`, muted, centered "No records found.").
- **Responsive**: At `lg`/`md`, table inside `<div class="table-wrap overflow-x-auto">` with horizontal scroll. At `sm`/`xs`, stacks vertically into `.glass-panel` cards with vertical key-value pairs.
- **Contrast**: Uses design-system tokens; active tab gradient `#059669 → #c2410c` (brand-600 → indigo-600), status badge `emerald-500/10` on `emerald-500` for Active. Dark mode inverts colors per `.dark` class rules.
- **Issues — "Coming soon" status**: The actual app does not have this screen built. Only the mockup exists. The my-web-app lacks `employee_list.html` entirely.
### Employee Form (not built — "Coming soon")

The `employee-form.html` mockup shows the complete design:

- **Centered `max-w-2xl` glass-panel modal** with form fields, PentadERP wordmark, theme toggle, role badge.
- **Fields**: First Name, Last Name, Email, Department dropdown, Role dropdown, Hire Date date picker, Separation Date date picker (conditional — shown only for employees who left; distinct from "deleted" status), Salary input (hidden without View Job History right), Job History textarea (hidden without that right). Save/Cancel buttons.
- **Add mode**: Form title "Add Employee Account".
- **Edit mode**: Form title "Edit Employee Account" pre-filled with sample data.
- **Right visibility**: Add Entry button and form visible to Superadmin/Admin only; hidden from User (ghosted/placeholder "No right" state). Salary and Job History hidden without View Job History right.
- **Data Privacy Act RA 10173**: Salary hidden without View Job History right; shown masked/greyed with notice when right is present. Separation date distinct from deleted status.
- **Responsive**: Fields stack vertically on narrow viewports; form remains centered.
- **Dark mode**: Paired `dark:` classes on all surfaces, text, interactive elements. Form fields have light/dark variants.
- **Accessibility**: Each input has matching explicit label and `required` where applicable. Close and theme buttons have accessible names. Decorative icons hidden from assistive tech.
- **Issues — "Coming soon" status**: The actual app does not have this screen built. Only the mockup exists. The my-web-app lacks `employee_form.html` entirely. No duplicate-date validation is present in the mockup (proposed as a future enhancement).
### Employee Profile (built — partially)

The `employee-profile.html` exists in `my-web-app/templates/`:

- **Header**: Employee photo/avatar (E-001 Maria Santos), name, role, department. Two-pane layout with tab navigation (Overview | Job History).
- **Overview mode**: Basic info, hire date, employment status. Job History tab **hidden/disabled** without View Job History right. Per RA 10173, salary field is hidden without the right; shown masked/greyed with notice when right present.
- **Job History mode**: Full job history table visible when right is present. Without right, tab is hidden/ghosted with note about Data Privacy Act RA 10173. Separation date distinct from "deleted" status.
- **Right visibility**: Job History tab visible only with right; otherwise hidden with proposed notice. Salary field hidden without the right.
- **Responsive**: Two-pane layout stacks vertically on narrow screens (max-w-2xl, full-width). Job history table becomes horizontally scrollable.
- **Dark mode**: Paired `dark:` classes on all surfaces, text, interactive elements. Overview and job history adapt to dark mode.
- **Accessibility**: Employee photo has alt text/aria-label. Tab navigation keyboard operable. Job history table has caption and scoped column headers. Action elements have accessible names.
- **Positive**: The screen is built and applies the design-system tokens (DM Sans, color palette, dark mode) correctly. The separation date distinction from deleted status is properly implemented.

### Job Timeline (static mockup — not in my-web-app templates)

The `job-timeline.html` mockup exists in `docs/ui-ux/mockups/s3/`:

- **Anatomy**: `<ol class="job-timeline-list">` with `<li class="job-timeline-item is-current">` for current entry, each with `job-timeline-card` containing job title, department, effective date, and Current badge.
- **Current badge**: `.badge-current` on newest entry; `font-semibold` on job title; uses `brand-600` (`#059669`).
- **Promotion/Transfer**: `fa-solid fa-arrow-up` + text "Promotion"; `fa-solid fa-exchange-alt` + text "Transfer"; `aria-label` on icon.
- **Empty state**: `job-timeline-empty` centered, `text-gray-500`, `p-6`.
- **Salary**: Hidden entirely per RA 10173 (not rendered).
- **Mobile**: Stacks vertically below `sm` breakpoint; reduces padding to `p-3`; single column, no horizontal scroll; empty state full-width.
- **Tokens**: Uses `brand-500` for job title text, `brand-600` for Current badge, `brand-500/10` for badge overlay, `rounded-full` for badges, `p-3`/`p-4`/`p-6` for cell padding, `focus:ring-2 focus-ring-brand-500` for focus.
- **Accessibility**: `aria-label="Employee job timeline"` on container, `aria-current="page"` on current entry, `aria-hidden="true"` on decorative marker, `sr-only` label for effective date, `aria-label="Promotion"`/`aria-label="Transfer"` on icons.
- **Gaps**: The job timeline mockup is a static HTML page, not a built template in `my-web-app`. No JS logic for dynamic date rendering or salary lookup.
## Fix List table

| ID | Screen | Issue | Severity | Fix | Owner |
|---|---|---|---|---|---|
| S3UX05-01 | Employee List | Screen not built — only mockup exists; app shows "Coming soon" | High | Build `employee_list.html` template with tabbed employee grid, status/stamp columns, and right-gated actions per guide facts | UI |
| S3UX05-02 | Employee Form | Screen not built — only mockup exists; app shows "Coming soon" | High | Build `employee_form.html` template with conditional fields (Salary/Job History hidden without View Job History right) | UI |
| S3UX05-03 | Employee Profile | Built screen exists but style.css lacks DM Sans and dark-mode tokens; contrast may differ from mockup | Medium | Apply shared design-system tokens (DM Sans, brand/slate colors, dark `:class` variables) to `my-web-app/static/style.css`; verify contrast | UI |
| S3UX05-04 | Job Timeline | Static mockup exists but not wired into app; no JS logic for dynamic rendering | Medium | Integrate job-timeline mockup markup into app as a template; add JS for effective-date rendering and Current badge logic | Developer |
| S3UX05-05 | Employee List | Tab labels use generic `record-tab` classes; count chips need `data-count` attributes and right-gated visibility | Medium | Implement tab navigation with `data-count-active`/`data-count-inactive`/`data-count-all`; hide tabs for User role; add count chip tokens | Developer |
| S3UX05-06 | Employee List | Salary/job history conditional on View Job History right not wired in list view | Medium | Ensure list table hides salary/stamp columns for User; shows masked/greyed notice when right present; add right-check logic per `S3-UIX-04-handoff-notes.md` | Developer |
| S3UX05-07 | Employee Form | Separation date field conditional logic not validated; must be distinct from "deleted" status | Low | Add frontend validation: separation date only enabled for employees with left-company status; distinct visual treatment from deleted checkbox | UI |
| S3UX05-08 | Employee List | No empty-state message for zero-result case | Low | Add centered "No employees found." message with appropriate next-action link (e.g., Add Employee) | UI |
| S3UX05-09 | Job Timeline | No sale-date helper UI or price lookup logic in built app | Low | If sale-date price lookup is a requirement, add date picker + applicable-price display following the mockup pattern; else document as future scope | Developer |
## Sprint 1-2 follow-up

Referencing the S1 usability review (`S1-UIX-05-usability-review.md`) and S2 review (`S2-UIX-05-usability-review.md`), the following carry-over items remain relevant for Sprint 3:

- **S1UX05-03 (All screens):** The app continues to use a separate palette/type/shape system without DM Sans or dark mode in the base styles. The S2 review confirmed that `base.html` imports DM Sans and `style.css` supports dark mode, but the S3 HR screens' `style.css` overrides may re-introduce the gap. **Owner: Developer** (verify S3 stylesheet consistency after applying fix S3UX05-03).

- **S1UX05-05 (Reset / Set password):** Successful reset/set responses still redirect without displaying the success message on the destination page. This general pattern affects multiple screens; the S3 job-history form add dialog similarly redirects without on-screen success confirmation after saving a job entry. **Owner: Developer** (investigate consistent pattern).

- **S1UX05-06 (Main page):** The built workspace omits the mockup's role badge, welcome banner, stat cards, chart, and Quick Navigation; module tiles use fragments without destinations. While out of scope for S3 (different module area), this confirms the team's awareness of design-system alignment gaps that also impact S3 screens when built. **Owner: Developer** (track alongside S3 work).

- **S1UX05-01 (Register / Login):** Registration claims approval although the form says approval is pending; pending status also has no distinct login outcome. This auth-flow issue is foundational; ensure S3 module screens do not repeat the same pending-account confusion (e.g., if an employee account is pending approval, the profile screen should reflect that state). **Owner: Developer**.

- **S2UX05-06 (Price History):** Stamp wording difference: "Stamp" in built app vs "Stamp Log" in mockup. This is a minor terminology carry-over that also appears in S3 employee list/stamp column. **Recommendation:** Harmonize to "Stamp Log" across all screens to match the reference, or update all mockups consistently.

- **S2UX05-07 (Price History):** Sale-date helper UI present but price calculation logic not in static template. Same concern applies to S3 employee list salary lookup — ensure if salary is shown, the "latest effective date not in the future" logic is implemented, or the display is a read-only notice.

---

**PR TITLE: S3-UIX-05: Usability Review of Sprint 3 Screens**

**PR DESCRIPTION:**
- Created `docs/ui-ux/S3-UIX-05-usability-review.md` with screen-by-screen comparison of Employee List, Employee Form, Employee Profile, and Job Timeline between built app and S3 mockups
- Identified 9 usability issues across 4 screens: screens not built ("Coming soon"), missing design-system tokens, right-gated visibility, salary/RA 10173 compliance, empty states, and terminology consistency
- Fix list table with ID, screen, issue, severity, fix, and owner (UI/Developer) for developer implementation
- Sprint 1-2 carry-over items: S1UX05-03 (palette/dark mode), S1UX05-05 (redirect success message), S1UX05-06 (main page gaps), S1UX05-01 (pending auth), S2UX05-06/07 (stamp/price logic terminology)

**PR LINK:** (will be created after git push)

**NOTES:**
1. HR module is "Coming soon" — only employee_profile.html is built; employee_list.html and employee_form.html need to be built from S3 mockups
2. Fix S3UX05-03 requires applying DM Sans and design-system tokens to my-web-app/static/style.css without touching app.py routes/permissions
3. Salary and Job History must remain hidden from User role per Data Privacy Act RA 10173; conditional visibility on View Job History right is the established pattern