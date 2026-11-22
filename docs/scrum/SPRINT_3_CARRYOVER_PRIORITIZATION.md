# Sprint 3 Carryover Prioritization

## Purpose and evidence basis

This is a date-free recommendation for reviewing possible Sprint 2 carryover. It is not a live-board export or a team-approved commitment. The external task-plan status column is stale, so no task is called incomplete solely because of its old status.

The Sprint 2 review records merged implementation/design PRs for the Customer and Product scope, but does not establish acceptance-test execution, defect retests, or final sign-off. That evidence gap makes testing the only carryover candidate supported by the reviewed records; it does not prove that the tests were not run elsewhere.

## Prioritization recommendation

| Priority | Candidate | Evidence | Recommendation | Decision status |
|---|---|---|---|---|
| High, conditional | Sprint 2 Customer, Product, price-history, and permission acceptance-test execution and retests | Acceptance specifications exist, but the reviewed Scrum/testing records do not show a consolidated run report or pass/fail results. | Ask the Tester to reconcile the evidence with the live board. If results are missing, prioritize the missing checks and any required retests before treating the related criteria as accepted. The detailed Sprint 3 plan already includes a Sprint 1–2 regression task; coordinate with it rather than creating duplicate work. | Pending live-board and Tester confirmation |
| As confirmed | Open Sprint 2 defects found by testing | No current defect list or test-run results were available in the reviewed records. | Carry only defects confirmed open on the live board, each with impact, owner, linked issue/PR, and retest criteria. Do not invent defect items. | No specific defect confirmed here |
| Do not carry as implementation by default | Merged Sprint 2 database, Customer, Product, price-history, and design changes | The evidence board links the relevant merged PRs. | Do not re-add these implementation tasks solely because the external status cells are stale. Reopen or create focused follow-up only if acceptance checks or the live board identify unfinished criteria. | Integrated PR evidence; acceptance remains separately verifiable |

## Check-in decisions

1. Reconcile Sprint 2 testing and defect status with the Tester and the live task board.
2. Confirm whether the planned Sprint 1–2 regression task covers any remaining Sprint 2 checks; avoid duplicate tasks.
3. If testing is still open, agree its scope and ownership before adding it to the active Sprint 3 commitment.
4. Keep the Sales-versus-Sprint-3 scope discrepancy separate; it is a planning conflict, not a confirmed Sprint 2 carryover.

No carryover is represented as team-approved until those checks are completed.

## Related records

- [Sprint 2 review and retrospective](SPRINT_2_REVIEW_AND_RETROSPECTIVE_REPORT.md)
- [Sprint 2 mid-sprint check and impediment log](MID_SPRINT_2_CHECK_AND_IMPEDIMENT_LOG.md)
- [Sprint 3 planning notes and board](SPRINT_3_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 2 velocity and burndown](SPRINT_2_VELOCITY_AND_BURNDOWN.md)

