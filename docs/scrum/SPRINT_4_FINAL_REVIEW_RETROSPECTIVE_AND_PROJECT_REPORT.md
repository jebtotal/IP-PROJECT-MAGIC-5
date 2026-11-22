# Sprint 4 Final Review, Retrospective, and Project Report

## Purpose and evidence basis

This is a repository-based final review, retrospective, and project summary. It
is not minutes of a confirmed team meeting. The external task plan's dates and
status cells are stale and are not treated as current evidence. Merged PRs
show integration, but do not by themselves establish that acceptance tests
passed, that the team accepted the work, or that a release was approved.

The user reports that the application is working. That could not be
independently confirmed against the current checkout: the focused Sales and
Reports test command fails while importing `app.py` because Flask reports that
the `api_list_sales` endpoint is registered more than once. The source also
assigns `REPORTS` twice; the later mapping conflicts with report handlers that
expect the earlier list of report definitions. No application code was changed
for this report.

## Executive summary

Sprint 4 has implementation and design evidence for Sales, payments, balances,
Reports, and audit-log access in the merged PRs listed below. The repository
also contains the sales/balance migration and its SQL test asset.

**Final disposition:** implementation is integrated, but current-checkout
verification and acceptance are not established. Do not mark the Sprint 4
release accepted or demo this checkout as verified until the import failure is
resolved, report rendering is checked, required tests pass, database setup is
confirmed, and the Tester/team sign-off is recorded.

## Sprint review

| Workstream | Evidence reviewed | Review outcome |
|---|---|---|
| Sales data and calculations | Merged PRs [#87](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/87) and [#89](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/89); [sales/balance migration](../../my-web-app/supabase/migrations/20261122000800_s4_dba_01_02_sales_balance_views.sql); [SQL test asset](../../my-web-app/supabase/tests/s4_dba_01_02_sales_balance_views.sql). | Database implementation and a focused test asset are present. The migration's applied state and SQL test execution result are not recorded here. |
| Sales application and payments | Merged PRs [#95](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/95), [#96](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/96), [#100](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/100), and [#103](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/103). | Feature work is integrated. The current checkout does not pass the focused test import, so the end-to-end sales and payment flow is not accepted by this report. |
| Reports and audit log | Merged PRs [#101](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/101) and [#104](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/104). | Feature work is integrated. Report rendering, per-report permissions, print/PDF behavior, and server-side audit authorization still need successful verification on the release candidate. |
| UI/UX | Merged PRs [#128](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/128), [#133](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/133), and [#146](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/146). | Design artifacts are integrated. Final usability acceptance is not recorded. |
| Peer evaluation | [Sprint 4 peer-evaluation collection record](SPRINT_4_PEER_EVALUATION_COLLECTION.md). | No completed responses, agreed rubric, or collection close-out is recorded. Keep raw peer feedback private. |
| Automated verification | `py -m unittest tests.test_sales_reports -v` from `my-web-app`. | Fails during app import with a duplicate Flask endpoint error (`api_list_sales`). A passing full-suite result for the current checkout is not available. |

### Acceptance evidence still required

- Verify sale-number allocation, valid references, sale-date pricing, line and
  transaction totals, payments, balances, rounding, and lifecycle behavior.
- Run all seven reports against known source records; test date and Top-N
  boundaries, per-report allowed/denied access, and print/PDF output.
- Verify that only authorized Superadmins can access the audit viewer.
- Run end-to-end and regression checks against a recorded build/commit and
  environment; record defects, retests, and Tester acceptance.
- Have the DB Admin confirm the target schema and migration state, and record
  the SQL test result using the approved safe database environment.

## Project report

Hope, Inc. ERP is a Flask web application using Supabase Auth and Supabase
PostgreSQL. Its intended workflows cover:

- Authentication, account approval, password setup/recovery, and
  permission-aware navigation.
- Customer and product records, including effective-dated product prices.
- Human Resources records for employees, departments, jobs, and job history.
- Sales transactions with detail lines, payments, totals, and balances.
- Seven reports: Top Customers, Product Master List, Top Products, Active
  Employees, All Employees, Employee Job History, and Top Sales.
- User and permission management, audit stamps, soft deletion, and the
  Superadmin audit-log viewer.

The project distinguishes Users, Admins, and Superadmins. Regular-user module,
action, and report access is permission-controlled; administrative access is
broader. The app depends on a correctly configured Supabase project, compatible
schema/views, grants, and row-level security policies. Migrations are not
applied automatically.

For local setup and environment configuration, see the
[project README](../../README.md) and [web-app README](../../my-web-app/README.md).

## Retrospective

These observations are based on repository evidence, not on attributed team
feedback or a confirmed retrospective meeting.

### What went well

- Database, application, reporting, and design work were integrated through
  focused PRs with traceable implementation history.
- The repository includes a sales/balance SQL test asset and a release
  checklist that separates implementation evidence from release approval.
- The application has a defined permission model and the Sprint 4 scope
  identifies report-specific and audit-viewer access as acceptance concerns.

### What should improve

- Keep a single active Sales API implementation and a single canonical report
  registry; duplicate route and report definitions currently prevent this
  checkout from passing app import and report-page checks.
- Run import/smoke tests and the focused feature tests in continuous
  integration so route-registration and rendering failures are caught before
  release review.
- Record test execution and sign-off, not just test-script existence or merged
  PRs. Keep database and application verification results linked to the exact
  candidate.
- Reconcile the Sales placement difference between the eight-week overview and
  the detailed Sprint 4 task plan.
- Complete peer evaluation collection through the agreed private process, and
  avoid placing raw responses in the repository.
- Agree on estimation and checkpoint practices before reporting future sprint
  velocity; the available records do not support a reliable Sprint 4 velocity
  figure.

## Follow-up actions

These are proposed close-out actions, not confirmed assignments or team
decisions.

| Action | Suggested coordinator | Completion evidence |
|---|---|---|
| Consolidate duplicate Sales routes and the report registry, then verify the app imports and reports render. | Developer | Focused tests and route/page smoke checks pass on a recorded candidate. |
| Run Sales, payment/balance, seven-report, audit-authorization, end-to-end, and regression checks. | Tester, with Developer and DB Admin | Linked test report with build, environment, outcomes, defects, and retests. |
| Confirm the reviewed migrations, target schema, backup, and SQL test result. | DB Admin | Recorded database verification in the approved environment; no unreviewed shared-database changes. |
| Confirm Sprint 4 scope and resolve the Sales placement discrepancy. | Scrum Master and team | Planning sources match the team-confirmed scope. |
| Collect and close out peer evaluations privately. | Scrum Master and team | The collection register and summary are completed without publishing raw feedback. |
| Record the review/demo decision and release approval, if granted. | Scrum Master and team | Candidate identifier, demo/test evidence, decision, and approver are recorded. |

## Final status

**S4-SM-05 report:** completed as an evidence-based project record.

**Sprint 4 acceptance/release:** not verified by the available records. The
user-reported working application is acknowledged, but the current repository
checkout's import failure prevents this report from recording a passing
verification or final sign-off.

## Related records

- [Sprint 4 planning notes and board](SPRINT_4_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 4 mid-sprint check and impediment log](MID_SPRINT_4_CHECK_AND_IMPEDIMENT_LOG.md)
- [Sprint 4 release checklist and demo script](SPRINT_4_RELEASE_CHECKLIST_AND_DEMO_SCRIPT.md)
- [Sprint 4 peer-evaluation collection](SPRINT_4_PEER_EVALUATION_COLLECTION.md)
- [Team working agreement and Definition of Done](TEAM_WORKING_AGREEMENT_DEFINITION_OF_DONE_ROLE_GUIDE.md)
