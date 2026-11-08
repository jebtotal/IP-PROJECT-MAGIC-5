
## Sprint 1 board (Weeks 1–2)

Sprint 1 establishes the application and database foundation, account access, and user administration. The statuses below reflect the Sprint 1 task list.

| ID | User story | Acceptance criteria | Owner | Status |
|---|---|---|---|---|
| S1-1 | As a team member, I want a working project and database setup so that the team can run and build the ERP. | The app starts using the documented setup; database connection configuration is available; schema changes can be applied using the migration setup. | Developer / DB Admin | Merged |
| S1-2 | As a new staff member, I want to register an account so that I can request access to the ERP. | A valid registration creates an account in pending status; invalid or incomplete details are rejected with a clear message; the new account cannot access protected features before approval. | Developer | Merged |
| S1-3 | As a registered user, I want to sign in, sign out, and recover my password so that I can securely access my account. | Valid credentials start a session; invalid credentials do not; sign-out ends access to protected pages; password reset uses an expiring, single-use token. | Developer | Merged |
| S1-4 | As an administrator, I want to manage user accounts so that I can approve access and maintain the team’s user list. | An authorized administrator can list and edit eligible users, approve pending users, and block or unblock accounts; administrators cannot manage Superadmin accounts. | Developer | Merged |
| S1-5 | As an administrator, I want to assign rights by module and action so that users only have the access they need. | Rights can be assigned per module/action; menus reflect assigned rights; unauthorized actions are rejected by the server, not just hidden in the interface. | Developer / DB Admin | Merged |
| S1-6 | As a signed-in user, I want a role-aware main page so that I can find the modules available to me. | The main page is available after sign-in; navigation reflects the signed-in user’s role and rights; protected pages remain inaccessible without permission. | Developer / UI/UX Designer | Merged |
| S1-7 | As a team member, I want agreed screen designs so that implementation has a consistent visual reference. | Design system, authentication wireframes, main-page and user-management wireframes, and the planned hi-fi mockups are available to the developer. | UI/UX Designer | Merged |
| S1-8 | As a tester, I want a test plan and acceptance criteria so that Sprint 1 behavior can be checked consistently. | Test plan and acceptance criteria are documented for Sprint 1; test cases cover authentication, account management, and permissions. | Tester | Merged |
| S1-9 | As a tester, I want to verify the main account and permission flows so that defects are found before release. | Registration, login/logout, password reset, user-management, permission, and main-page checks are run; failures are recorded as bugs and fixes are retested. | Tester | Not started |

### Sprint 1 board columns

Use these columns on the team board and move each story as work progresses:

**Backlog → To Do → In Progress → In Review → Done**

Use **Blocked** as a flag when a story cannot move forward. The board status should reflect the current issue/PR and test state; a merged PR does not by itself mean the story has passed all acceptance criteria.

## Eight-week module plan

| Sprint | Weeks | Module(s) from the guide | Planned outcome |
|---|---:|---|---|
| Sprint 1 | 1–2 | User Management | Establish project/database setup, accounts, roles, approval/blocking, rights, and the role-aware main page. |
| Sprint 2 | 3–4 | Customers; Products | Deliver customer CRUD with soft delete/restore, then product CRUD and effective-dated price history. |
| Sprint 3 | 5–6 | Human Resources; Sales | Deliver employees, jobs, departments, and job history; then sales headers and detail lines using valid customers, employees, and products. |
| Sprint 4 | 7–8 | Reports | Deliver the guide’s read-only reports, verify report access rights, and run end-to-end checks across all six modules. |

### Module completion checkpoints

- **Customers (Sprint 2):** Authorized users can add, view, edit, and soft-delete customers; permitted administrators can restore them; users see only active records.
- **Products (Sprint 2):** Authorized users can manage products and price-history entries; the current price is selected from the latest effective price that is not in the future.
- **Human Resources (Sprint 3):** Authorized users can manage employees, jobs, departments, and job history; job-history records link to valid employees, jobs, and departments.
- **Sales (Sprint 3):** Authorized users can create sales with valid customer and employee references and add valid product lines; totals equal the sum of line totals.
- **Reports (Sprint 4):** The guide’s reports return the expected data, respect the viewer’s report rights, and produce consistent totals with the underlying sales data.
- **User Management (Sprint 1):** Authorized administrators can manage eligible accounts and rights; blocked users cannot sign in, and server-side authorization prevents disallowed actions.

The schedule is a planning target, not a claim that later-sprint modules are already implemented. Review scope and capacity at each sprint planning session, and raise dependency or schedule risks early.
