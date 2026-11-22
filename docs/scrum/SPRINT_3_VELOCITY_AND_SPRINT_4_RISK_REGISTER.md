# Sprint 3 Velocity and Sprint 4 Risk Register

## Velocity update

No numerical Sprint 3 velocity is reported. The reviewed records do not define an agreed estimation unit or a reliable accepted-work baseline, and the external task-plan dates and status cells are stale. Merged PRs show integration but are not an estimate of accepted work.

The Sprint 3 PR evidence is summarized in the [Sprint 3 planning notes and board](SPRINT_3_PLANNING_NOTES_AND_BOARD.md). It should not be converted to velocity without team-agreed estimates and confirmation that the linked work meets the Definition of Done.

| Metric | Result | Basis |
|---|---|---|
| Sprint 3 velocity | Not calculable from the reviewed records | No agreed estimate unit or verified accepted-work totals |
| Sprint 3 burndown trend | Not calculable from the reviewed records | No reliable scope baseline or sequence of remaining-work snapshots |

## Sprint 4 risk register

This is an initial, date-free register based on the detailed Sprint 4 task breakdown and repository evidence. The S4 tasks and risks below are not claims that work is unstarted. Several related PRs are already integrated; the live board and acceptance evidence should determine what remains.

| ID | Risk | Potential impact | Evidence / trigger | Mitigation or response | Suggested coordinator | Review state |
|---|---|---|---|---|---|---|
| S4-RISK-01 | Sales is assigned to Sprint 3 in the eight-week overview but Sprint 4 in the detailed task plan. | Scope and capacity assumptions may conflict. | Conflicting planning records; S3 planning notes leave the placement for team confirmation. | Reconcile both planning sources and use the team-confirmed scope for forecasting and review. | Scrum Master | Needs team confirmation |
| S4-RISK-02 | Sales data depends on valid Customers, Employees, Products, and effective-dated prices. | Invalid references or a wrong sale-date price could produce incorrect transactions. | Sales header/detail and price-as-of work is represented by PRs [#95](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/95) and [#96](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/96); current-price query work by [#76](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/76). | Verify foreign-key choices and price selection for no price, past, current, and future-effective entries; record test results. | Developer and DB Admin, with Tester | Verification to confirm |
| S4-RISK-03 | Line totals, sale totals, payments, and balances may disagree because of calculation, rounding, or update behavior. | Incorrect amounts can affect customer balances and reports. | Sales totals and balance queries and payment work are represented by PRs [#87](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/87), [#100](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/100), and [#103](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/103). | Use known fixtures to compare line sums, sale totals, payments, and balances; test edits, deletes, and boundary/rounding cases. | DB Admin and Tester | Verification to confirm |
| S4-RISK-04 | Sales deletion may conflict with active detail lines or payments. | Deleting referenced transactions could orphan records or distort balances/reports. | Sales delete/restore is in the detailed Sprint 4 plan; related balance/soft-delete work is present in PR [#103](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/103). | Verify server/database guards for sales with details or payments and verify permitted restore behavior. | Developer and DB Admin, with Tester | Rule and test evidence to confirm |
| S4-RISK-05 | Reports may return incorrect totals or expose data to users without the corresponding report right. | Users may rely on inaccurate or unauthorized business information. | Report queries and UI are represented by PRs [#89](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/89) and [#101](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/101); the detailed plan calls for seven reports, filters, per-report rights, and print/PDF. | Test each report against source data, date-range and Top-N boundaries, access granted/denied, and print/PDF output. | Developer and Tester, with DB Admin | Verification to confirm |
| S4-RISK-06 | End-to-end and regression testing may be squeezed by the breadth of Sales, Payments, Reports, and audit work. | Cross-module defects may remain undetected at close-out. | Sprint 4 task plan includes end-to-end and full-regression work; earlier sprint reports identify missing test evidence. | Confirm test ownership and environments early; record run results, defects, blockers, and retests separately from merged status. | Tester and Scrum Master | Capacity and evidence to confirm |
| S4-RISK-07 | Audit-log access or filtering may expose sensitive activity beyond the intended role. | User or administrative data could be visible to unauthorized principals. | The detailed plan specifies a Superadmin audit-log viewer; implementation work is represented by PR [#104](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/104). | Verify server-side role enforcement, filter behavior, and response contents with authorized and unauthorized accounts. | Developer and Tester | Verification to confirm |
| S4-RISK-08 | Stale dates/statuses and missing velocity inputs make schedule or capacity forecasts unreliable. | Forecasts may overstate completion or hide carryover. | External task plan has no agreed estimate unit and its status column is not current; see [Sprint 2 velocity and burndown](SPRINT_2_VELOCITY_AND_BURNDOWN.md). | Use the live team board, agree the scope/estimate method, and forecast from accepted work and recorded checkpoints rather than PR counts. | Scrum Master and team | Tracking method to confirm |

## Follow-up

Use the live team board to confirm which risks still apply, assign accountable owners, and record mitigations or accepted exceptions. Revisit the register when scope or implementation changes; do not mark a risk resolved solely because a PR merged.

## Related records

- [Sprint 4 planning notes and board](SPRINT_4_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 3 planning notes and board](SPRINT_3_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 3 mid-sprint check and impediment log](MID_SPRINT_3_CHECK_AND_IMPEDIMENT_LOG.md)
- [Sprint 3 carryover prioritization](SPRINT_3_CARRYOVER_PRIORITIZATION.md)
- [Sprint 2 velocity and burndown](SPRINT_2_VELOCITY_AND_BURNDOWN.md)
- The detailed Sprint 4 task breakdown is maintained outside the project folder.

