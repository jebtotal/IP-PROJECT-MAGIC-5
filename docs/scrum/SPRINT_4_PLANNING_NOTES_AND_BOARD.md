# Sprint 4 Planning Notes and Board

## Purpose and evidence basis

This is a date-free planning record using the detailed per-member task breakdown as the working scope baseline. It is not a live task tracker; the external task-plan status cells and calendar dates are not treated as current.

## Scope decision to confirm

The [eight-week module plan](SPRINT_1_BOARD_AND_8_WEEK_MODULE_PLAN.md) lists Reports in Sprint 4 and places Sales in Sprint 3. The detailed per-member task breakdown places Sales, Payments, Reports, balances, and the audit-log viewer in Sprint 4.

**Working baseline:** use the detailed Sprint 4 breakdown for Sales and Reports, while asking the team to confirm the Sales move and reconcile both planning sources. This document does not claim that the team has approved the change.

## Sprint goal

Complete and verify the Sales-to-Reports flow: create sales using valid customers, employees, and products; apply the correct price for the sale date; calculate totals and balances; record payments; and provide authorized reports and audit-log access.

## Scope and acceptance

- **Sales header and detail:** Transaction numbers are unique and system-assigned. Customer, employee, and product references are valid. Sale details use the price effective on the transaction date; sale totals equal the sum of their lines.
- **Payments and balances:** Payment records update the relevant transaction/customer balance consistently with sales totals and recorded payments.
- **Sales lifecycle:** Soft deletion and restore follow the agreed rights and data-integrity rules; sales with dependent detail/payment records are handled safely.
- **Reports:** The seven planned reports return data consistent with source records, support the planned date-range/Top-N filters, enforce per-report rights, and support print/PDF output.
- **Audit log:** Only the intended Superadmin role can view audit activity; filters and returned fields respect server-side authorization.
- **Verification:** Sales, payment/balance, report-rights, end-to-end, and regression checks have recorded outcomes. Merged implementation PRs or test assets alone do not establish acceptance.

## Evidence board

The external task-plan status column is not used as current status. The table records merged PR evidence available in repository history and the verification still needed.

| Workstream | Planned focus | Evidence found | Evidence-based status |
|---|---|---|---|
| Sales data and calculations | Sales totals, line amounts, payment balance, and report queries. | Merged PRs [#87](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/87) and [#89](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/89). | Database query work integrated; end-to-end reconciliation is not established by merge history alone. |
| Sales application | Sale header, detail lines with date-effective price, payment, balances, and sales lifecycle. | Merged PRs [#95](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/95), [#96](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/96), [#100](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/100), and [#103](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/103). | Implementation evidence integrated; acceptance-test results are not established here. |
| Reports and audit log | Seven report views and Superadmin audit-log viewer. | Merged PRs [#101](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/101) and [#104](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/104). | Implementation evidence integrated; report rights, output, and audit authorization still require recorded verification. |
| UI/UX | Sales/detail wireframes, line-total guidance, and payment/balance wireframes. | Merged PRs [#128](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/128), [#133](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/133), and [#146](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/146). | Design artifacts integrated. |
| Testing | Sales/date-price, payment/balance, seven reports, end-to-end, regression, defects, and final sign-off. | A database test script for sales totals and balance views exists in the repository. | Test assets exist; no consolidated Sprint 4 pass/fail report or final sign-off was found in the reviewed Scrum/testing documents. |

## Dependencies and risks

| Risk or dependency | Planning response |
|---|---|
| Sales is assigned to different sprints in the two planning sources. | Confirm and reconcile scope before using either document as a commitment. |
| Sales depends on valid Customer, Employee, Product, and price-history data. | Test valid/invalid references and historical, current, and future-effective prices against the transaction date. |
| Line totals, sale totals, payments, and balances must agree. | Reconcile calculations with known fixtures; test edits, deletes, rounding, and payment updates. |
| Reports depend on correct source queries and report-specific permissions. | Compare outputs to source data, exercise filters/Top-N boundaries, and verify allowed and denied access plus print/PDF output. |
| Earlier sprint test/carryover evidence is uncertain. | Reconcile carryover on the live board and include required regression checks without duplicating already verified work. |
| Dates/status cells and velocity inputs are stale or unavailable. | Use the live board for actual ownership/status; do not forecast from old dates or count PRs as velocity. |

See the [Sprint 3 velocity and Sprint 4 risk register](SPRINT_3_VELOCITY_AND_SPRINT_4_RISK_REGISTER.md) for additional risk detail.

## Planning and review notes

- Confirm scope, owners, and task status against the live team board; this record intentionally omits obsolete dates and status cells.
- Link each task to its implementation/design PR and to test evidence where applicable.
- Keep “merged,” “tested,” and “accepted” as separate states under the existing Definition of Done.
- Record any remaining defects, blocked checks, scope changes, and carryover before final sign-off.

## Related records

- [Sprint 1 board and eight-week module plan](SPRINT_1_BOARD_AND_8_WEEK_MODULE_PLAN.md)
- [Sprint 3 planning notes and board](SPRINT_3_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 3 velocity and Sprint 4 risk register](SPRINT_3_VELOCITY_AND_SPRINT_4_RISK_REGISTER.md)
- [Sprint 4 mid-sprint check and impediment log](MID_SPRINT_4_CHECK_AND_IMPEDIMENT_LOG.md)
- [Sprint 4 release checklist and demo script](SPRINT_4_RELEASE_CHECKLIST_AND_DEMO_SCRIPT.md)
- [Team working agreement and Definition of Done](TEAM_WORKING_AGREEMENT_DEFINITION_OF_DONE_ROLE_GUIDE.md)

