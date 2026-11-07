# S1-UIX-05 — Usability Review of Sprint 1 Screens

## Scope and method

Reviewed the Flask templates, CSS, browser-side handlers, and relevant routes in `my-web-app/`, then compared them with `docs/ui-ux/mockups/s1/` and the S1 design-system document. Application files were read-only.

This is a **static code review**; the app was not run. The app README requires Python 3.10+, Supabase credentials, and a configured `.env`. This workspace had no `.env`, no `py` launcher, and only the Windows Store `python` alias, so a live screen/responsive/contrast check was not available. Findings below are based on the source, not a browser-rendered session.

## Overall observations

- The app provides working server routes and browser-side flows for authentication, password recovery, a workspace landing page, user management, and rights editing.
- The application styles do not use the documented shared design system: no DM Sans import or dark theme is present; its CSS uses a separate slate/blue palette, smaller radii, and basic spacing. The design system specifies DM Sans, warm remapped colors, pill buttons, rounded-xl inputs, and paired light/dark treatments ([design system](./S1-UIX-01-design-system.md#L98), [style.css](../../my-web-app/static/style.css#L7)).
- The simple templates do have useful semantic foundations: associated labels, native required/type constraints, live form messages, and a native `<dialog>` for Rights. Color contrast and actual focus visibility were not measured in a browser.

## Screen-by-screen review

### Login and logout — **Partially built**

**What matches:** Login has labeled, required email and password fields, a submit action, a forgot-password link, a registration link, and an announced form-message region. Login submits to an authentication endpoint; the workspace has a POST logout form. Sources: [login.html](../../my-web-app/templates/login.html#L12), [login.js](../../my-web-app/static/login.js#L1), [index.html](../../my-web-app/templates/index.html#L18), [app.py](../../my-web-app/app.py#L689).

**What deviates / usability issues:**
- Compared with the [login mockup](./mockups/s1/login.html#L27), the built screen has no PentadERP-styled card, DM Sans, theme toggle, password visibility control, or shared color/radius/input treatments. The password toggle is part of the mockup; the actual password input has no adjacent control ([login.html](../../my-web-app/templates/login.html#L12)).
- A pending profile is not handled as a separate sign-in state: the login route rejects `blocked` and `rejected`, but does not reject or message `pending`. This conflicts with the registration copy that says approval is required. A pending account may therefore sign in if Supabase Auth permits it, without clear approval feedback ([app.py](../../my-web-app/app.py#L713), [register.html](../../my-web-app/templates/register.html#L13)).
- Invalid credentials produce a live error message, which is helpful. The form does not provide custom focus styling; the browser default is left in place ([login.html](../../my-web-app/templates/login.html#L13), [style.css](../../my-web-app/static/style.css#L131)).
- Logout is an action in the sidebar, not a separate screen. It clears the session and redirects, but provides no explicit “you are signed out” confirmation; the login screen is the next page ([index.html](../../my-web-app/templates/index.html#L23), [app.py](../../my-web-app/app.py#L740)).

### Register — **Partially built**

**What matches:** Registration uses labeled required fields, email type validation, a password length constraint, pending-approval guidance, and an announced result message. The handler temporarily disables the submit button and reports server errors ([register.html](../../my-web-app/templates/register.html#L13), [register.js](../../my-web-app/static/register.js#L1)).

**What deviates / usability issues:**
- The [registration mockup](./mockups/s1/register.html#L38) asks for First Name, Last Name, and Email only. The built form instead asks for Full name and Password. That changes both the data breakdown and the proposed “password set on first login” flow; it also duplicates the separate password-setup screen ([register.html](../../my-web-app/templates/register.html#L17), [set_password.html](../../my-web-app/templates/set_password.html#L12)).
- The page tells people their account is pending, but successful registration responds “Your account is approved.” The README describes new profiles as pending. This contradictory success message can mislead users about when they can sign in ([register.html](../../my-web-app/templates/register.html#L13), [app.py](../../my-web-app/app.py#L881), [my-web-app README](../../my-web-app/README.md)).
- Visual styling is the same unthemed browser-default presentation described above; there is no branded responsive card or dark-mode treatment ([style.css](../../my-web-app/static/style.css#L7), [registration mockup](./mockups/s1/register.html#L27)).

### Forgot/reset password and set password — **Built**

**What matches:** The app has separate reset-request, token-based new-password, and first-login set-password pages. Inputs are labeled and required, enforce an eight-character minimum, and provide live feedback; server-side handlers check confirmation and distinguish invalid/expired reset links ([forgot_password.html](../../my-web-app/templates/forgot_password.html#L12), [reset_password.html](../../my-web-app/templates/reset_password.html#L12), [set_password.html](../../my-web-app/templates/set_password.html#L12), [app.py](../../my-web-app/app.py#L656)).

**What deviates / usability issues:**
- These pages have no shared card styling, DM Sans, dark-mode variant, or password show/hide control. The password fields therefore lack the visibility affordance used by the login and proposed first-login design ([reset_password.html](../../my-web-app/templates/reset_password.html#L15), [set_password.html](../../my-web-app/templates/set_password.html#L15), [registration mockup](./mockups/s1/register.html#L62)).
- On a successful reset, the handler redirects immediately to Login, so the “Password reset. You can now log in.” response message is never rendered to the user. The set-password flow similarly redirects to the workspace without an on-screen success confirmation ([reset-password.js](../../my-web-app/static/reset-password.js#L5), [set-password.js](../../my-web-app/static/set-password.js#L5), [app.py](../../my-web-app/app.py#L684)).
- The expired/invalid token response is surfaced in the live region after submission, but opening an expired-link page gives no explanatory state until the user submits the form ([reset_password.html](../../my-web-app/templates/reset_password.html#L13), [app.py](../../my-web-app/app.py#L671)).

### Main page / workspace — **Partially built**

**What matches:** A signed-in workspace has a labeled navigation region, a role-dependent User Management link, a welcome heading, and module tiles filtered by View permissions. It also has an empty-module state and an accessible alert for permission-loading failures ([index.html](../../my-web-app/templates/index.html#L13), [app.py](../../my-web-app/app.py#L213)).

**What deviates / usability issues:**
- The [main-page mockup](./mockups/s1/main-page.html#L18) includes role variants, a role badge, welcome banner, stat cards, a chart area, and Quick Navigation. The built workspace only presents a greeting and permitted module tiles; those dashboard components and the theme toggle are not built ([index.html](../../my-web-app/templates/index.html#L28)).
- Sidebar and module-card navigation are much simpler than the mockup and do not use the design-system colors, DM Sans, card treatment, or dark theme. The current module tile URLs are `#<slug>`; no module sections exist in the template, so the links do not navigate into a module screen ([index.html](../../my-web-app/templates/index.html#L35), [style.css](../../my-web-app/static/style.css#L23)).
- Basic responsiveness is present: the workspace sidebar stacks below 42rem and module tiles use auto-fit. There is no corresponding dark-mode or responsive dashboard treatment because the stat/chart dashboard itself is absent ([style.css](../../my-web-app/static/style.css#L53)).
- **Not yet built:** the individual Customer, Product, HR, Sales, and Reports destination screens are not present in the inspected templates; no findings are inferred about those screens.

### User Management — **Partially built**

**What matches:** The page has a user list, table wrapper with horizontal overflow, Add User form, status/role actions, and a Rights dialog. The server filters Admin lists to regular users and protects Superadmin accounts. Remove has a confirmation prompt ([user_management.html](../../my-web-app/templates/user_management.html#L25), [style.css](../../my-web-app/static/style.css#L138), [app.py](../../my-web-app/app.py#L279), [user-management.js](../../my-web-app/static/user-management.js#L244)).

**What deviates / usability issues:**
- Add User is a permanent inline form rather than the modal shown in the [User Management mockup](./mockups/s1/user-management.html#L48). Edit is a browser `prompt()` that only updates Full name; it is not an edit dialog and does not expose the other fields shown by the mockup ([user_management.html](../../my-web-app/templates/user_management.html#L25), [user-management.js](../../my-web-app/static/user-management.js#L201)).
- Table markup omits a caption and explicit `scope="col"` on headers, unlike the mockup. The table scrolls horizontally on narrow screens, but action buttons can become crowded ([user_management.html](../../my-web-app/templates/user_management.html#L47), [mockup](./mockups/s1/user-management.html#L27)).
- The Superadmin list API returns Admin and User accounts but excludes Superadmin accounts, while the [Superadmin mockup](./mockups/s1/user-management.html#L32) includes a protected Superadmin row. This makes the built list less representative of all accounts and leaves no visible indication of protected Superadmin records ([app.py](../../my-web-app/app.py#L294)).
- Block/Unblock, Approve, and role changes run without confirmation or an explicit success message; only Remove prompts for confirmation. These actions change access or authority and should clearly identify the affected account and resulting state ([user-management.js](../../my-web-app/static/user-management.js#L157), [user-management.js](../../my-web-app/static/user-management.js#L217)).
- The Rights button is rendered for every row, including Admin rows in the Superadmin list, while the mockup shows it only for User rows. The backend permits Superadmins to edit Admin rights, so this is a role/visibility deviation from the mockup rather than a broken action ([user-management.js](../../my-web-app/static/user-management.js#L148), [app.py](../../my-web-app/app.py#L509), [mockup](./mockups/s1/user-management.html#L33)).
- The Users table has no explicit empty-state message; if the request succeeds with an empty list, the body remains blank ([user_management.html](../../my-web-app/templates/user_management.html#L58), [user-management.js](../../my-web-app/static/user-management.js#L132)).
- Colors, font, radii, spacing, and dark-mode behavior do not match the [shared design system](./S1-UIX-01-design-system.md#L98); the global stylesheet has no dark theme or font declaration ([style.css](../../my-web-app/static/style.css#L7)).

### Rights dialog — **Built**

**What matches:** The native modal dialog has a heading, Cancel/Save actions, All/None controls, module-level parent checkboxes, and action checkboxes for the five modules. Rights load/save errors and successful saves are announced; the module parent checkbox reflects partial selection ([user_management.html](../../my-web-app/templates/user_management.html#L64), [user-management.js](../../my-web-app/static/user-management.js#L37)).

**What deviates / usability issues:**
- The [Rights mockup](./mockups/s1/rights-dialog.html#L17) uses a dark-mode-aware, scrollable card and two-column action groups. The built dialog uses generic browser styles and a fixed four-column fieldset grid, which may be cramped on a narrow viewport; CSS only changes the workspace shell at its breakpoint ([style.css](../../my-web-app/static/style.css#L158), [style.css](../../my-web-app/static/style.css#L186)).
- The module-parent checkbox is dynamically inserted into a `<legend>` without an associated `<label>` or accessible name. The action checkboxes do have wrapping labels ([user-management.js](../../my-web-app/static/user-management.js#L42), [user-management.js](../../my-web-app/static/user-management.js#L55)).
- The modal has a named heading and native `showModal()` behavior, but no visible close icon; users must use Cancel or browser-native dialog controls ([user_management.html](../../my-web-app/templates/user_management.html#L64), [user-management.js](../../my-web-app/static/user-management.js#L97)).

## Fix list

| ID | Screen | Issue | Severity | Expected behavior / reference mockup | Suggested owner |
|---|---|---|---|---|---|
| S1UX05-01 | Register / Login | Registration claims approval although the form says approval is pending; pending status also has no distinct login outcome. Align the API success message and login gating/feedback with the actual approval state. ([register.html](../../my-web-app/templates/register.html#L13), [app.py](../../my-web-app/app.py#L719), [app.py](../../my-web-app/app.py#L881)) | High | Tell the user the true pending/approved state and show a clear pending-access message, consistent with the [auth wireframe](./wireframes/S1-UIX-02-wireframes-auth.md#L52). | Developer |
| S1UX05-02 | Register | Form asks for full name and password instead of first name, last name, and email; this conflicts with the separate first-login password flow. ([register.html](../../my-web-app/templates/register.html#L17), [set_password.html](../../my-web-app/templates/set_password.html#L12)) | Medium | Match the [register mockup](./mockups/s1/register.html#L38); keep password creation in the set-password flow if that remains the product requirement. | Developer |
| S1UX05-03 | All screens | The app uses a separate palette/type/shape system, lacks DM Sans and dark mode, and does not apply the mockups’ spacing, radii, or controls. ([style.css](../../my-web-app/static/style.css#L7), [design system](./S1-UIX-01-design-system.md#L98)) | Medium | Apply shared design tokens and components consistently; verify both themes and the existing narrow-screen layout. | Developer |
| S1UX05-04 | Login / Set / Reset password | Password fields have no show/hide affordance; the login mockup and proposed first-login preview include one. ([login.html](../../my-web-app/templates/login.html#L16), [set_password.html](../../my-web-app/templates/set_password.html#L15), [login mockup](./mockups/s1/login.html#L45)) | Low | Add a keyboard-operable, accessibly named toggle with state updated between Show and Hide. | Developer |
| S1UX05-05 | Reset / Set password | Successful reset/set responses redirect without displaying the success message. ([reset-password.js](../../my-web-app/static/reset-password.js#L5), [set-password.js](../../my-web-app/static/set-password.js#L5)) | Medium | Confirm completion on the destination page or show an announced success state before navigation. | Developer |
| S1UX05-06 | Main page | Built workspace omits the mockup’s role badge, welcome banner, stat cards, chart, and Quick Navigation; module tiles use fragments without destinations. ([index.html](../../my-web-app/templates/index.html#L28), [main-page mockup](./mockups/s1/main-page.html#L49)) | Medium | Implement the intended dashboard components and route each permitted module action to a real destination; keep unimplemented module screens clearly unavailable. | Developer |
| S1UX05-07 | User Management | Add is inline and Edit uses a name-only browser prompt, not the mockup’s Add/Edit dialog and fields. ([user_management.html](../../my-web-app/templates/user_management.html#L25), [user-management.js](../../my-web-app/static/user-management.js#L201)) | Medium | Use a labeled Add/Edit dialog with clear save/cancel behavior and fields appropriate to each operation ([mockup](./mockups/s1/user-management.html#L48)). | Developer |
| S1UX05-08 | User Management | Rights is offered for Admin rows, although the mockup shows it only for User rows. Superadmins can edit Admin rights in the backend, so clarify whether this is an intentional product-rule change. ([user-management.js](../../my-web-app/static/user-management.js#L148), [app.py](../../my-web-app/app.py#L509)) | Medium | Match the [wireframe](./wireframes/S1-UIX-03-wireframes-main-usermgmt.md#L176) visibility rule or update the approved design to explicitly include Admin targets. | Developer |
| S1UX05-09 | User Management | Block/Unblock, Approve, and role changes have no confirmation or explicit success feedback. ([user-management.js](../../my-web-app/static/user-management.js#L157), [user-management.js](../../my-web-app/static/user-management.js#L217)) | Medium | Confirm consequential changes with the target user and resulting state; announce completion or failure. | Developer |
| S1UX05-10 | Rights dialog | The module checkbox has no explicit accessible label, and the fixed four-column action grid can be cramped on small screens. ([user-management.js](../../my-web-app/static/user-management.js#L42), [style.css](../../my-web-app/static/style.css#L186)) | Medium | Provide a programmatic label and a responsive rights layout; follow the [Rights mockup](./mockups/s1/rights-dialog.html#L27). | Developer |
| S1UX05-11 | User Management | Successful empty user results render as a blank table. ([user-management.js](../../my-web-app/static/user-management.js#L132), [user_management.html](../../my-web-app/templates/user_management.html#L58)) | Low | Show a clear, announced empty state with the appropriate next action. | Developer |
| S1UX05-12 | User Management | The Superadmin list excludes Superadmin accounts, although the mockup shows a protected Superadmin row. ([app.py](../../my-web-app/app.py#L294), [mockup](./mockups/s1/user-management.html#L32)) | Low | Show protected accounts read-only, or document the intentional omission in the product rules. | Developer |

### Not-yet-built screens

The individual ERP module destination screens (Customer, Product, Human Resources, Sales, and Reports) are not present in the inspected templates. They are listed as not yet built; no screen-specific usability findings are inferred for them.
