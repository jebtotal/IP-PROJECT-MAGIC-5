# S3-UIX-05b — Usability Review Fixes (Owner: UI)

## Scope

Fixed High/Medium items marked owner = UI from `docs/ui-ux/S3-UIX-05-usability-review.md` in HR templates/static CSS/JS. Visual and markup only; every form action, field name, id, CSRF token and all Python left untouched.

## S3UX05-01 — Employee List Template (High, UI)

**Status:** Fixed

**What was done:** Created `my-web-app/templates/employee_list.html` from the S3 mockup and guide facts. The template implements:

- **Superadmin/Admin view:** Page header with role badge, employee table with columns Employee No./Name/Role/Department, toolbar with tab navigation (Active/Inactive/All showing counts), Status badge column, Stamp column (CREATED/EDITED/DELETED/RESTORED + user + datetime), Restore button on deleted rows (shaded background). Add Employee button visible to Superadmin/Admin only.
- **User view:** Active rows only. No tabs. No Status or Stamp columns. No action column buttons. Salary/job history hidden per RA 10173.
- **Search/filters:** Tab navigation serves as the filter UI (Active/Inactive/All).
- **Empty state:** Centered "No employees found." message with Add Employee link.
- **Responsive:** At `lg`/`md`, table inside `<div class="table-wrap overflow-x-auto">` with horizontal scroll. At `sm`/`xs`, stacks vertically into `.glass-panel` cards.
- **Contrast:** Uses design-system tokens; active tab gradient `#059669 → #c2410c` (brand-600 → indigo-600), status badge `emerald-500/10` on `emerald-500` for Active.
- **Dark mode:** Colors invert per `.dark` class rules.
- **Right visibility:** Add Employee button and action column buttons visible to Superadmin/Admin only; hidden from User.

**Files created:** `my-web-app/templates/employee_list.html`
---
## S3UX05-02 — Employee Form Template (High, UI)

**Status:** Fixed

**What was done:** Created `my-web-app/templates/employee_form.html` from the S3 mockup and guide facts. The template implements:

- **Centered `max-w-2xl` glass-panel modal** with form fields, PentadERP wordmark, theme toggle, role badge.
- **Fields:** First Name, Last Name, Email, Department dropdown, Role dropdown, Hire Date date picker, Separation Date date picker (conditional — shown only for employees who left; distinct from "deleted" status), Salary input (hidden without View Job History right), Job History textarea (hidden without that right).
- **Add mode:** Form title "Add Employee Account".
- **Edit mode:** Form title "Edit Employee Account" pre-filled with sample data.
- **Right visibility:** Add Entry button and form visible to Superadmin/Admin only; hidden from User (ghosted/placeholder "No right" state). Salary and Job History hidden without View Job History right.
- **Data Privacy Act RA 10173:** Salary hidden without View Job History right; shown masked/greyed with notice when right is present. Separation date distinct from deleted status.
- **Responsive:** Fields stack vertically on narrow viewports; form remains centered.
---
## S3UX05-03 — Design-System Tokens in style.css (Medium, UI)

**Status:** Fixed

**What was done:** Updated `my-web-app/static/style.css` to include shared design-system tokens consistent with `S1-UIX-01-design-system.md` and the S3 mockups. Changes:

- Added explicit CSS custom properties for the design-system color palette: `--brand-50`, `--brand-100`, `--brand-500` (`#10b981`), `--brand-600` (`#059669`), `--indigo-600` (`#c2410c`), `--sky-400` (`#fb923c`), `--slate-50` (`#f5f5f4`), `--slate-100` (`#e7e5e4`), `--slate-400` (`#78716c`), `--slate-500` (`#57534e`), `--slate-600` (`#44403c`), `--slate-700` (`#292524`), `--slate-800` (`#1c1917`), `--slate-900` (`#0c0a09`).
- Added dark mode `.dark` class counterparts: `--brand-500` (`#34d399`), `--brand-600` (`#059669`), `--indigo-600` (`#c2410c`), `--slate-800` (`#292524`), `--slate-900` (`#0c0a09`), `--slate-300` (`#a8a29e`).
- The existing `font-family: "DM Sans", system-ui, sans-serif;` was already present; token variables now align with the design system's remapped Tailwind colors (`brand` = emerald, `indigo` = terracotta, `sky` = warm orange, `slate` = warm stone/charcoal).
- The `button { border-radius: 9999px !important; }` rule was already present, ensuring all buttons render as fully pill-shaped per the design system.
- No form field names, ids, actions, CSRF tokens, routes, or permission logic were modified.

**Files modified:** `my-web-app/static/style.css`
---
## Gaps & Assumptions

1. The employee_list.html and employee_form.html templates are visual markup only — backend data binding, form submission handling, and role-gated permission checks are pending implementation by the development team.
2. The style.css token updates provide the design-system color vocabulary; individual components may still need `class` bindings (e.g., `bg-brand-500`, `text-indigo-600`, `dark:bg-slate-900`) to fully render the intended contrast.
3. The "Coming soon" grayed-out pill button pattern (`opacity-50`, `not-allowed`, `text-[10px] font-bold uppercase tracking-wider`) is not applied to the newly created templates since those screens are designed as fully functional per the guide facts.
4. The separation date conditional logic (distinct from deleted status) and the View Job History right-gated visibility are implemented as frontend markup/hints; the backend must enforce the actual data access controls.