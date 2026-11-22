# Sprint 2 Review and Retrospective

## Purpose and evidence basis

This is a date-free, evidence-based review of the Sprint 2 Customer and Product scope. It summarizes merged pull requests and repository documents; it is not minutes of a confirmed Sprint Review or a substitute for team feedback. The original sprint dates and task-plan status column are not treated as current.

Merged PRs confirm integration, not release readiness or acceptance-test completion.

## Sprint outcome

| Area | Evidence reviewed | Evidence-based result |
|---|---|---|
| Database foundations | PRs [#75](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/75)–[#80](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/80) | Views/indexes, price-as-of query, validation, delete guards, demo data, and search tuning are integrated. |
| Customer workflow | PR [#81](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/81) | Customer implementation is integrated. |
| Product workflow | PR [#82](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/82) | Product implementation is integrated. |
| Price history and permissions | PR [#84](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/84) | Current-price marker and permission-matrix work are integrated. |
| Design and usability | PRs [#70](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/70)–[#73](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/73), [#93](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/93), [#97](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/97), and [#98](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/98) | Wireframes, handoff/states, usability review, and follow-up design changes are integrated. |
| Testing and acceptance | [Customer checks](../testing/s2-bld-01-customers-sprint1.md), [Product checks](../testing/s2-bld-02-products-module.md), and [permission/price-history checks](../testing/s2-permissions.md) | Test specifications are available. The reviewed records do not establish execution results, defect retests, or acceptance sign-off. |

**Overall:** The main implementation and design work has merged. The available evidence is insufficient to claim that all Sprint 2 acceptance criteria passed or that the sprint is release-ready.

## Review discussion points

- Demonstrate Customer and Product workflows against the agreed acceptance criteria.
- Show current-price behavior for missing, past, and future-effective prices.
- Review server-side permission denials and child-record delete guards.
- Attach actual test-run results and any defect/retest evidence before calling those criteria verified.
- Confirm which work is accepted, remains open, or is carried forward using the live team board.

These are review prompts, not claims that a demonstration or team decision has already occurred.

## Retrospective observations

These observations are drawn from repository evidence, not from individual team feedback.

### What appears to have gone well

- Database foundations and the Customer/Product implementations were delivered through linked PRs.
- Design artifacts and usability follow-ups were integrated alongside feature work.
- The project has explicit acceptance specifications for customer lifecycle, products, prices, and permissions.

### What should improve

- Keep test execution and retest evidence visible alongside implementation; test specifications alone do not show whether behavior passed.
- Replace reliance on the outdated task-plan schedule/status snapshot with the team’s current source of truth.
- Agree an estimation method and capture remaining-work checkpoints before reporting velocity or burndown. Those metrics cannot be reconstructed reliably from the available records.
- Keep “merged,” “tested,” and “accepted” as distinct states.

## Proposed follow-up actions

| Action | Suggested coordinator | Completion evidence |
|---|---|---|
| Reconcile open work and ownership against the live issue/PR board; do not reuse superseded schedule values. | Scrum Master | Current board reflects linked issues/PRs and team-confirmed ownership. |
| Record Customer, Product, permission, and regression test runs, including failures, blocked cases, and retests. | Tester, with Developer and DB Admin for fixes | Linked test report or issue evidence with build/environment and outcomes. |
| Agree one estimation unit and a consistent scope/checkpoint method before the next velocity/burndown update. | Scrum Master and team | Team-approved baseline and checkpoint records; see [Sprint 2 velocity and burndown](SPRINT_2_VELOCITY_AND_BURNDOWN.md). |

These are proposed actions for team confirmation, not assigned commitments.

## Related records

- [Sprint 2 planning notes and evidence board](SPRINT_2_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 2 mid-sprint check and impediment log](MID_SPRINT_2_CHECK_AND_IMPEDIMENT_LOG.md)
- [Sprint 1 retrospective action follow-up](SPRINT_2_RETRO_ACTION_FOLLOW_UP.md)
- [Team working agreement and Definition of Done](TEAM_WORKING_AGREEMENT_DEFINITION_OF_DONE_ROLE_GUIDE.md)

