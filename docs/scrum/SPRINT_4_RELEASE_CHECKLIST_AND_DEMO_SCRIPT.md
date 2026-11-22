# Sprint 4 Release Checklist and Demo Script

## Purpose and release status

This is a release-readiness checklist and a gated demo script, not a release approval or a record that the checks have passed. Complete the checklist against the exact release candidate and record evidence before calling the Sprint 4 work accepted or release-ready.

The [Sprint 4 mid-sprint check](MID_SPRINT_4_CHECK_AND_IMPEDIMENT_LOG.md) records that test assets and merged implementation PRs do not establish test execution or acceptance. The Sales-versus-Sprint-3 scope discrepancy also remains for team confirmation in the [Sprint 4 planning notes](SPRINT_4_PLANNING_NOTES_AND_BOARD.md).

## Current-checkout demo gate

Sales and Reports routes and templates are present in the checked-out source.
However, the current focused test command
`py -m unittest tests.test_sales_reports -v` fails while importing `app.py`:
Flask reports that the `api_list_sales` endpoint is registered more than once.
The source also defines `REPORTS` twice, so report rendering still needs a
successful run after the route-registration issue is resolved.

The user reports that the live application is working, but that report does not
confirm that the running process matches this checkout. Do not present this
checkout as release-ready or use it for the feature demo until it imports,
passes the required checks, and the Sales, Payments, Reports, and audit-log
flows are verified on the exact candidate build.

## Release checklist

### Scope and candidate

- [ ] Confirm the team-approved Sprint 4 scope, including the Sales placement conflict, and update the planning sources.
- [ ] Record the candidate branch, commit or tag, build identifier, and intended demo/release environment.
- [ ] Confirm that the candidate contains the required features; verify `/sales` and `/reports` do not render placeholders.
- [ ] Reconcile the candidate against the live team board. Do not use the external plan's stale dates/status cells as release evidence.
- [ ] Confirm there are no unreviewed changes in the candidate and that required PR review/approval and merge evidence is available.

### Database and configuration

- [ ] Have the DB Admin confirm the target Supabase project, schema state, migration order, and compatibility before applying database changes.
- [ ] Confirm the relevant migration and test assets are present: [sales/balance migration](../../my-web-app/supabase/migrations/20261122000800_s4_dba_01_02_sales_balance_views.sql) and [sales/balance SQL test](../../my-web-app/supabase/tests/s4_dba_01_02_sales_balance_views.sql).
- [ ] Apply reviewed migrations through the team's approved process and retain the result. The [application setup guide](../../my-web-app/README.md) states that this repository has no automated migration runner.
- [ ] Run the sales/balance SQL test only against a scratch or copied database as instructed by the script; record its output. Do not treat the rollback-only test fixtures as demo data.
- [ ] Confirm a protected pre-release backup and a reviewed recovery/rollback procedure. If using the repository backup scripts, verify restore only against a separate, pre-created target; never restore over the shared team database.
- [ ] Verify the app's required environment settings and target URL without exposing credentials. Keep service-role, database, SMTP, and session secrets server-side and out of source control, screenshots, and demo materials.

### Verification and acceptance

- [ ] Record test build/commit, environment, test data, owner, pass/fail/blocked result, defects, and retests.
- [ ] Verify sale-date price selection, line and sale totals, payment status, transaction/customer balances, and expected rounding/edge cases.
- [ ] Verify sales create/edit/delete/restore behavior and access rights, including dependent details and payments.
- [ ] Verify all seven reports against source records, including date-range and Top-N boundaries, per-report access rights, and print/PDF output.
- [ ] Verify the audit viewer's server-side Superadmin restriction and denied access for an unauthorized role.
- [ ] Complete end-to-end and regression checks, including authentication and role/permission behavior.
- [ ] Confirm defects and deferred work are recorded on the live board, with an owner and disposition.
- [ ] Obtain Tester acceptance evidence and team release approval; distinguish these from PR merge status.

### Release record

Complete this only after the gates above have been reviewed:

| Field | Record |
|---|---|
| Candidate branch / commit / tag | |
| Build and target environment | |
| Database migration/backup evidence | |
| Test report and unresolved defects | |
| Tester acceptance | |
| Release decision and approver | |

## Gated demo script

### Before the demo

1. Select the verified candidate and record its branch/commit and demo URL.
2. Confirm the Sales, Reports, and audit screens are available in that build; otherwise use the fallback walkthrough below.
3. Use an approved non-production/demo environment with synthetic data and separate demo accounts for Sales access and Superadmin access.
4. Confirm the demo data has a valid customer, employee, products, and effective-dated prices. Do not use real customer, employee, payment, or audit data.
5. Confirm the demo accounts have only the permissions needed for their steps. Do not display passwords, tokens, environment values, or database connection strings.

### Walkthrough

1. **Open the workspace.** Sign in with the approved Sales demo account and show the dashboard and available module navigation.
2. **Create a sale.** Open Sales, create a transaction using the prepared synthetic customer and salesperson, and choose a transaction date with known price-history entries.
3. **Check date-effective pricing and totals.** Add the prepared products and quantities. Show the unit prices selected for the transaction date and verify each line amount and the sale total against the approved expected values.
4. **Record a payment.** Record the prepared partial payment. Show the transaction's paid amount and remaining balance, then show the corresponding customer balance if available.
5. **Show reports.** Run the planned reports with the prepared date-range and Top-N values. Compare a sales/customer/product result with the known source records; demonstrate print/PDF only if verified in this candidate.
6. **Show authorization behavior.** With an account lacking the relevant report right, demonstrate that access is denied. Do not change permissions during the demonstration unless that action is an approved part of the test.
7. **Show audit access.** Sign in separately with the approved Superadmin demo account and show the permitted audit view/filter. If safe and verified, demonstrate that a non-Superadmin account is denied.
8. **Close with status.** State which checks passed, any known limitations, and whether release approval has been granted. Do not infer acceptance from the demo, merged PRs, or screenshots alone.

### Fallback if the feature UI is unavailable

Do not simulate a successful live workflow. If the selected candidate cannot
start, fails verification, or still displays placeholders, use this fallback:

1. State exactly which UI or verification gate is unavailable in the selected build.
2. Show the approved scope and linked implementation evidence from the [Sprint 4 planning notes](SPRINT_4_PLANNING_NOTES_AND_BOARD.md).
3. Show the database migration and test-script contents as implementation/test assets only; explicitly state whether execution results are available.
4. End with the remaining release gates and owners from the [mid-sprint impediment log](MID_SPRINT_4_CHECK_AND_IMPEDIMENT_LOG.md).

## Related records

- [Sprint 4 planning notes and board](SPRINT_4_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 4 mid-sprint check and impediment log](MID_SPRINT_4_CHECK_AND_IMPEDIMENT_LOG.md)
- [Sprint 4 final review, retrospective, and project report](SPRINT_4_FINAL_REVIEW_RETROSPECTIVE_AND_PROJECT_REPORT.md)
- [Team working agreement and Definition of Done](TEAM_WORKING_AGREEMENT_DEFINITION_OF_DONE_ROLE_GUIDE.md)
