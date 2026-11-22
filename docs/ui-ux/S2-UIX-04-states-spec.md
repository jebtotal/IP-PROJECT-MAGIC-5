# S2-UIX-04 - Empty, Error and Confirm-Delete States

## 1. Purpose

Define reusable empty, validation, save-error, delete, blocked-delete, restore, success, and coming-soon states for Customer and Product screens.

The HTML specimen is at [states.html](mockups/s2/states.html).

## 2. Source priority

1. Available PentadERP reference HTML - look and confirmation treatment.
2. Sprint 2 plan and guide summary - Customer/Product behavior, soft delete, restore, and delete blocking.
3. Built app - visible labels, confirmation helper, toast behavior, and “Coming soon” wording.

The named `Private-Design-Reference` directory and separate student guide were not present as files in the workspace. The available read-only reference HTML was not located in the repository, and no separate guide file was found. This spec follows the existing Sprint 2 wireframes, the S1 design system, and `my-web-app`.

## 3. Reusable states

### 3.1 Empty list

- Heading: `No customers found`
- Supporting text: `Add your first customer to start managing records.`
- Primary action: `Add Customer`
- Product reuse: `No products found` and `Add your first product to start managing records.`
- For a filtered or otherwise unusable module, do not show the empty-list Add action unless Add permission exists.

### 3.2 No search match

- Heading: `No matching records`
- Supporting text: `Try a different search term or clear the search.`
- Secondary action: `Clear search`
- Keep the search field and status tabs visible.

### 3.3 Validation error

**PROPOSED (not in reference):** the reference does not define invalid-field borders or a custom validation system.

- Use a red-500 two-pixel border and red-500 focus ring.
- Associate the field with its message using `aria-describedby`.
- Set `aria-invalid="true"` on the field.
- Use `role="alert"` and `aria-live="assertive"` on field feedback.
- Example message: `Customer name is required.`
- Product reuse: `Product name is required.`

### 3.4 Save error

- Baseline live red-tinted alert: `The customer could not be saved. Please try again.`
- Product reuse: `The product could not be saved. Please try again.`
- Use `role="alert"` and `aria-live="assertive"`.
- Keep the form open and the Save action available again.

## 4. Delete and restore confirmations

### 4.1 Confirm delete

- Dialog title: `Please confirm`
- Built copy pattern: `Move Acme Corporation to Inactive?`
- Reuse: `Move [Record Name] to Inactive?`
- Cancel: neutral secondary action.
- Proceed: solid red-600 `Confirm` action.
- Soft delete only; this is not permanent deletion.
- Cancel leaves the record unchanged.

### 4.2 BLOCKED delete

**Guide 4.3 / S2-DBA-04 requirement:** block deletion when a record still has active child records.

- Dialog type: `role="alertdialog"`
- Title: `Cannot delete record`
- Customer sample: `Acme Corporation is still referenced by active sales records. It cannot be deleted.`
- Product sample: `Industrial Widget A is still referenced by active sales records. It cannot be deleted.`
- Use an amber warning icon and neutral Close action.
- Do not show or enable Confirm in the blocked state.
- `aria-live="assertive"` may announce the alert; `aria-labelledby` and `aria-describedby` remain required.

### 4.3 Confirm restore

- Title: `Restore customer?` or `Restore product?`
- Supporting copy: `[Record Name] will return to Active.`
- Cancel leaves the record inactive.
- Restore returns the record to Active.
- Restore is visible only to a permitted administrator.

## 5. Success toast

- Success is emerald-600 with white text.
- Use `role="status"` and `aria-live="polite"`.
- Examples:
  - `Customer saved successfully.`
  - `Customer moved to Inactive.`
  - `Customer restored successfully.`
  - `Product saved successfully.`
- The built app removes toasts after approximately 3.5 seconds.

## 6. Coming soon

Baseline exact wording:

> Coming soon. This module is not available yet.

- Show the module name above or beside the exact sentence.
- Use the standard large white/dark rounded panel.
- Keep the breadcrumb, module pill, role badge, theme toggle, sidebar, user card, and logout pattern.
- Add a restrained icon and a `Back to workspace` action.
- Mark Product and any unavailable module as `Not built yet`.

## 7. Role and rights variants

| State | Superadmin/Admin | User |
|---|---|---|
| Empty list | Add shown only with Create right | No Create action unless Create right |
| No search match | Reuse shared table state | Reuse shared table state |
| Delete confirm | Delete right required | Hidden unless Delete right |
| Restore confirm | Delete right + administrator role | Hidden |
| Coming soon | Module unavailable | Module unavailable |

Normal Users see active records only and must not see Inactive/All tabs or restore controls.

## 8. Accessibility

- Validation, save, and blocked-delete feedback use alert semantics appropriate to urgency.
- Success feedback uses `role="status"` and polite live-region behavior.
- Confirm dialogs use a named heading and description.
- All icon-only controls need `aria-label`.
- Preserve keyboard focus, Escape dismissal where supported, and return focus to the initiating action.
- Do not rely on color alone: include text and icons.
- Empty states use a heading and supporting copy, not color alone.

## 9. Tokens

Reuse [S1-UIX-01-design-system.md](S1-UIX-01-design-system.md):

- Primary: `brand-600` / `brand-500`
- Success: `emerald-600`
- Error: `red-500`, `red-600`, `red-700`
- Warning/blocked: `amber-500`
- Neutral surface: `bg-white`, `dark:bg-slate-900`, `gray-200` / `gray-800`
- Modal: rounded-3xl, `p-7`, neutral overlay
- Toast: fixed top-right, rounded-2xl, shadow

## 10. Gaps & Assumptions

| Topic | Available source | Gap or decision |
|---|---|---|
| Private-Design-Reference | Named folder was absent. | Used existing mockups and the S1 design system; reference-specific visuals not claimed. |
| Student guide 4.3 | Named guide was absent as a separate file. | Applied the task-provided blocked-delete rule and marked exact guide wording unverified. |
| Reference exact modal copy | Built app is the available implementation fact for `Please confirm` and `Move ... to Inactive?`. | Followed built app copy. |
| Invalid field style | Not defined by the reference. | Marked proposed and reused existing red/emerald design tokens. |
| Blocked delete copy | Guide rule is known; exact customer/product sentence is not supplied. | Wording is proposed; behavior and active-record condition follow guide 4.3 / S2-DBA-04. |
| Customer name | User context supplied Acme Corporation for prior Sprint 2 mockups. | Used Acme Corporation only as a static example. |
| Product state | Product is not built in the app. | Marked Product and coming-soon coverage not built yet. |

Source priority applied: built-app wording and structure where available, Sprint 2 behavior for rights/soft delete/delete blocking, and existing design-system tokens for proposed details.
