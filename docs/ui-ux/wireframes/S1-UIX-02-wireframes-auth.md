# S1-UIX-02 — Authentication Wireframes

Low-fidelity, grayscale structure-only wireframes based on `PentadERP_index (FINAL).html` and its inline auth handlers. The existing dialogs follow the shared design system's centered `max-w-md` modal, `p-8` spacing, stacked fields, uppercase 10px labels, and rounded input/button treatment. No colors are shown below.

**Notation:** `[P]` marks an element or behavior that is **PROPOSED (not in reference)**. `Required?` indicates field requirement; it is N/A for non-fields.

## 1. Login

**Purpose:** Sign in with an email and password. The modal is shown to unauthenticated visitors.

**Layout:**

```text
+--------------------------------------+
|                         [1] Close    |
| [2] Sign In                          |
|                                      |
| [3] Email Address                    |
|     +----------------------------+   |
|     | you@company.com            |   |
|     +----------------------------+   |
|                                      |
| [4] Password                         |
|     +-------------------------[5]+   |
|     | ••••••••                    |   |
|     +-----------------------------+   |
|                                      |
| [6] Sign In                          |
|                                      |
| [7] Forgot password? [P]             |
| [8] Need an account? Register        |
+--------------------------------------+
```

**Numbered annotations**

1. Close button. **Required?** N/A. Closes the login modal; no next screen is specified.
2. Heading, “Sign In”. **Required?** N/A. Static modal heading. Demo-oriented supporting copy is omitted with the out-of-scope demo controls.
3. Email input, type `email`, label “Email Address”, placeholder `you@company.com`. **Required?** Yes (`required`). The login handler trims and looks up the email.
4. Password input, type `password`, label “Password”, masked placeholder. **Required?** Yes (`required`). The reference handler does not read or verify this field; password validation is **PROPOSED (not in reference)**.
5. Show/hide button, type `button`, accessible label changes between “Show password” and “Hide password”. **Required?** N/A. Toggles the password input type between `password` and `text`, and swaps the eye icon.
6. Submit button, “Sign In”. **Required?** N/A. Submits to `handleLogin`. The current handler enters the dashboard for an existing user regardless of password or status; if the email is unknown, it creates an active user and signs in. Credential/status gating is **PROPOSED (not in reference)**.
7. “Forgot password?” link. **Required?** N/A. **PROPOSED (not in reference):** would open the existing Reset Password request modal. No such link or reset-modal opener exists in the Login modal markup/handlers.
8. “Need an account? Register” link. **Required?** N/A. Present in the reference; switches from Login to Register.

**Navigation:** Close → dismiss; Sign In → dashboard per current demo handler; Register → Register modal; Forgot password? → Reset request modal **[PROPOSED link]**.

**Role/state:** Unauthenticated visitor. The login modal also contains “1-Click Role Login” demo buttons and “Continue with Google”; both are excluded from these Sprint 1 wireframes as demo-only/out of scope.

## 2. Register

**Purpose:** Submit a new account request. The handler creates a `user` with `pending` status. There is no password field; password setup is a separate proposed first-login flow.

**Layout:**

```text
+--------------------------------------+
|                         [1] Close    |
| [2] Create Account                   |
|     Join the PentadERP platform.     |
|                                      |
| [3] First Name       [4] Last Name  |
|     +---------------+ +------------+ |
|     |               | |            | |
|     +---------------+ +------------+ |
|                                      |
| [5] Email                            |
|     +----------------------------+   |
|     |                            |   |
|     +----------------------------+   |
|                                      |
| [6] Submit Registration              |
|                                      |
| [7] Already registered? Sign In      |
+--------------------------------------+
```

**Numbered annotations**

1. Close button. **Required?** N/A. Closes the Register modal.
2. Heading and supporting copy. **Required?** N/A. Static “Create Account” and invitation text.
3. First Name input, type `text`. **Required?** Yes. Trimmed by `handleRegister`.
4. Last Name input, type `text`. **Required?** Yes. Trimmed by `handleRegister`.
5. Email input, type `email`, label “Email”. **Required?** Yes. Trimmed by `handleRegister`.
6. Submit button, “Submit Registration”. **Required?** N/A. Creates a record with role `user`, status `pending`, and sample permissions; shows “Registration submitted.” and switches to Login.
7. “Already registered? Sign In” link. **Required?** N/A. Switches to Login.

**Navigation:** Close → dismiss; Submit Registration → info toast, then Login; Sign In → Login. No password is collected here.

**Role/state:** Unauthenticated visitor creating an account. New account state is pending; the reference does not define the approval UI or prevent pending accounts from using its demo login handler.

## 3. Reset password — request form

**Purpose:** Request a reset email from the existing Reset Password modal.

**Layout:**

```text
+--------------------------------------+
|                         [1] Close    |
| [2] Reset Password                   |
|                                      |
| [3] Email                            |
|     +----------------------------+   |
|     |                            |   |
|     +----------------------------+   |
|                                      |
| [4] Send Reset Link                  |
+--------------------------------------+
```

**Numbered annotations**

1. Close button. **Required?** N/A. Closes the reset modal.
2. Heading, “Reset Password”. **Required?** N/A. Present in the reference; no supporting paragraph is shown.
3. Email input, type `email`, label “Email”. **Required?** Yes. Browser required/email constraints apply.
4. Submit button, “Send Reset Link”. **Required?** N/A. `handleReset` shows “Reset email dispatched.” and closes the modal. The handler does not generate or send a tokenized link.

**Navigation:** Close → dismiss; Send Reset Link → info toast and close. A route from Login to this modal is **PROPOSED** because none is wired in the reference.

**Role/state:** Unauthenticated user who can access the reset modal. The source does not specify account-existence feedback.

## 4. Reset password — new-password form

**PROPOSED (not in reference).** The reference has no emailed token route, token validation, new-password form, or reset completion handler.

**Purpose:** Let a user with a valid emailed reset token set a replacement password.

**Layout:**

```text
+--------------------------------------+
|                         [1] Close    |
| [2] Choose a new password            |
|                                      |
| [3] New Password                     |
|     +--------------------------[4]+  |
|     |                            |  |
|     +----------------------------+  |
| [5] Confirm New Password           |
|     +--------------------------[6]+  |
|     |                            |  |
|     +----------------------------+  |
|                                      |
| [7] Save New Password                |
+--------------------------------------+
```

**Numbered annotations**

1. Close/cancel button. **Required?** N/A. **PROPOSED:** exits without changing the password.
2. Heading. **Required?** N/A. **PROPOSED:** explains that the user is setting a new password.
3. New password input, type `password`. **Required?** Yes. **PROPOSED:** accepts the replacement password.
4. Show/hide button. **Required?** N/A. **PROPOSED:** follows the reference `togglePasswordVisibility` behavior.
5. Confirm new password input, type `password`. **Required?** Yes. **PROPOSED:** must match field 3.
6. Show/hide button. **Required?** N/A. **PROPOSED:** follows the reference toggle behavior.
7. Submit button, “Save New Password”. **Required?** N/A. **PROPOSED:** validates the token and matching passwords, saves the new password, and returns to Login. Token expiry/reuse rules are not in the reference.

**Navigation:** Valid token link from email → this form; successful submit → Login **[PROPOSED]**; invalid/expired/used token → error state 6d **[PROPOSED]**.

**Role/state:** Unauthenticated user following a reset email link with a valid token **[PROPOSED]**.

## 5. Set password on first login

**PROPOSED (not in reference).** The reference has no first-login password setup state or password-saving handler.

**Purpose:** Allow an approved account that has no password yet to create one before entering the application.

**Layout:**

```text
+--------------------------------------+
| [1] Set your password                |
|     Your account is approved.        |
|                                      |
| [2] New Password                     |
|     +--------------------------[3]+  |
|     |                            |  |
|     +----------------------------+  |
| [4] Confirm Password              |
|     +--------------------------[5]+  |
|     |                            |  |
|     +----------------------------+  |
|                                      |
| [6] Set Password                     |
+--------------------------------------+
```

**Numbered annotations**

1. Heading and status explanation. **Required?** N/A. **PROPOSED:** shown only after account approval on first sign-in.
2. New password input, type `password`. **Required?** Yes. **PROPOSED:** receives the initial password.
3. Show/hide button. **Required?** N/A. **PROPOSED:** follows the reference `togglePasswordVisibility` behavior.
4. Confirm password input, type `password`. **Required?** Yes. **PROPOSED:** must match field 2.
5. Show/hide button. **Required?** N/A. **PROPOSED:** follows the reference toggle behavior.
6. Submit button, “Set Password”. **Required?** N/A. **PROPOSED:** saves the password and proceeds to the dashboard.

**Navigation:** Approved account's first login → this form; successful submit → dashboard **[PROPOSED]**; mismatch → inline validation **[PROPOSED]**.

**Role/state:** Approved user whose password has not yet been set **[PROPOSED]**. Approval and first-login detection are not implemented in the reference.

## 6. Login and reset error/feedback states

All states below are **PROPOSED (not in reference)** except the existing empty `#loginError` container. The source defines that container's hidden markup but does not populate it. `handleLogin` does not check passwords or user status, and `handleReset` does not issue or validate reset tokens.

### 6a. Wrong credentials

**Purpose:** Explain that the sign-in attempt failed without leaving Login.

```text
+--------------------------------------+
| [1] Sign In                          |
| [2] Email                            |
|     +----------------------------+   |
|     +----------------------------+   |
| [3] Password                       [4]|
|     +----------------------------+   |
| [5] Credentials not recognized.      |
| [6] Sign In                          |
| [7] Forgot password?                 |
+--------------------------------------+
```

1. Heading. **Required?** N/A. **PROPOSED:** Login heading.
2. Email input, type `email`, required. **Required?** Yes. **PROPOSED:** retain entered email after failure.
3. Password input, type `password`, required. **Required?** Yes. **PROPOSED:** allow correction and resubmission.
4. Show/hide button. **Required?** N/A. **PROPOSED:** reference toggle behavior.
5. Inline error text. **Required?** N/A. **PROPOSED:** reuse the existing `#loginError` container; the example copy is not in the reference.
6. Sign In submit button. **Required?** N/A. **PROPOSED:** retry authentication.
7. Forgot password link. **Required?** N/A. **PROPOSED:** open Reset request form.

**Navigation:** Retry → Login; Forgot password? → Reset request form **[PROPOSED]**. **Role/state:** unauthenticated user whose credentials fail **[PROPOSED]**.

### 6b. Blocked user

**Purpose:** Inform a blocked user that sign-in is unavailable.

```text
+--------------------------------------+
| [1] Sign In                          |
| [2] Email                            |
|     +----------------------------+   |
| [3] Password                       [4]|
|     +----------------------------+   |
| [5] This account is blocked.         |
| [6] Sign In                          |
+--------------------------------------+
```

1. Heading. **Required?** N/A. **PROPOSED:** Login heading.
2. Email input, type `email`, required. **Required?** Yes. **PROPOSED:** identify the attempted account.
3. Password input, type `password`, required. **Required?** Yes. **PROPOSED:** retain/allow correction as appropriate.
4. Show/hide button. **Required?** N/A. **PROPOSED:** reference toggle behavior.
5. Inline blocked-state message. **Required?** N/A. **PROPOSED:** shown when account status is blocked; example copy is not in the reference.
6. Sign In submit button. **Required?** N/A. **PROPOSED:** remains available for retry after account status changes.

**Navigation:** Remains on Login; no unblock destination is defined. **Role/state:** user whose account status is blocked **[PROPOSED]**.

### 6c. Pending, not yet approved

**Purpose:** Explain that a submitted registration is awaiting approval.

```text
+--------------------------------------+
| [1] Sign In                          |
| [2] Email                            |
|     +----------------------------+   |
| [3] Password                       [4]|
|     +----------------------------+   |
| [5] Account pending approval.        |
|     Try again after approval.        |
| [6] Sign In                          |
+--------------------------------------+
```

1. Heading. **Required?** N/A. **PROPOSED:** Login heading.
2. Email input, type `email`, required. **Required?** Yes. **PROPOSED:** identify the submitted account.
3. Password input, type `password`, required. **Required?** Yes. **PROPOSED:** no password exists until the proposed first-login setup.
4. Show/hide button. **Required?** N/A. **PROPOSED:** reference toggle behavior.
5. Inline pending-state message. **Required?** N/A. **PROPOSED:** shown for `pending` status; sample copy is not in the reference.
6. Sign In submit button. **Required?** N/A. **PROPOSED:** recheck after approval.

**Navigation:** Remains on Login until approval; after approval, first login → screen 5 **[PROPOSED]**. **Role/state:** registered user with pending approval **[PROPOSED]**.

### 6d. Expired or used reset token

**Purpose:** Explain why a reset link cannot be used and offer a way to request another.

```text
+--------------------------------------+
| [1] Reset link unavailable           |
| [2] This link has expired or         |
|     already been used.               |
|                                      |
| [3] Request a new reset link          |
| [4] Back to Sign In                  |
+--------------------------------------+
```

1. Error heading. **Required?** N/A. **PROPOSED:** shown from token validation.
2. Explanatory message. **Required?** N/A. **PROPOSED:** covers expired or already-used token.
3. Request-new-link button. **Required?** N/A. **PROPOSED:** opens Reset request form.
4. Back to Sign In link. **Required?** N/A. **PROPOSED:** returns to Login.

**Navigation:** Request a new reset link → screen 3 **[PROPOSED]**; Back to Sign In → screen 1. **Role/state:** unauthenticated user with an expired or previously used reset token **[PROPOSED]**.

## Screen flow

| Screen | Action | Next screen |
|---|---|---|
| Login | Select Register | Register (reference) |
| Login | Select Forgot password? | Reset password request (link is **PROPOSED**; modal exists but is unreachable from Login) |
| Login | Submit valid credentials | Dashboard (**PROPOSED** authentication behavior; current demo handler opens dashboard without checking password/status) |
| Login | Submit invalid credentials | Wrong-credentials state 6a (**PROPOSED**) |
| Login | Submit blocked account | Blocked state 6b (**PROPOSED**) |
| Login | Submit pending account | Pending state 6c (**PROPOSED**) |
| Register | Submit registration | Pending user is created; info toast; return to Login (reference) |
| Register | Select Sign In | Login (reference) |
| Reset request | Submit email | Info toast; close modal (reference); no actual token/link is generated |
| Reset request | Reset email link is opened | New-password form 4 (**PROPOSED**) |
| New-password form 4 | Submit valid token and matching password | Login (**PROPOSED**) |
| New-password form 4 | Submit expired/used token | Error state 6d (**PROPOSED**) |
| Approved pending user | First login before password exists | Set-password form 5 (**PROPOSED**) |
| Set-password form 5 | Submit matching passwords | Dashboard (**PROPOSED**) |

## Gaps & Assumptions

- The reference Login has no “Forgot password?” link. Although `#resetModal` and `handleReset` exist, no reference markup or handler opens Reset from Login; the Login link and that navigation are **PROPOSED (not in reference)**.
- The Login modal's “1-Click Role Login” buttons and “Continue with Google” are demo-only and out of scope for these Sprint 1 wireframes; neither is included in the screens.
- Screens 4 (new password from a token link) and 5 (set password on first login) are **PROPOSED (not in reference)**.
- Wrong-credentials, blocked-user, pending-user, and expired/used-token states are **PROPOSED (not in reference)**. The `#loginError` element exists but is empty/hidden and is not updated by `handleLogin`.
- `handleLogin` currently ignores the password value, creates an unknown email as an active user, and does not check `pending` or `blocked` status. The failure and state-gating wireframes describe the requested intended flows, not current handler behavior.
- `handleRegister` creates a pending user and switches to Login, but no approval mechanism or approval screen is present in the inspected reference. Approval is assumed to occur through a separate process not depicted here.
- `handleReset` only displays an info toast and closes the modal; no email delivery, token lifecycle, or reset completion flow exists in the reference.
- All proposed copy and destinations are illustrative structure only, not verified production behavior.
