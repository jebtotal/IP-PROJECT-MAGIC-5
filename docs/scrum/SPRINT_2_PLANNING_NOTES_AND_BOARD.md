# Sprint 2 Planning Notes and Board

## Purpose

This is a formal, date-free record of the Sprint 2 scope and the implementation evidence available in the repository. Sprint calendar dates, week numbers, and due days are intentionally omitted because the working schedule changed. This is an evidence summary, not a live task tracker.

## Sprint goal

Deliver the Customer and Product workflows, including effective-dated price history, with database integrity and permission checks. Keep implementation, design, and verification visible through linked pull requests and acceptance artifacts.

## Scope and acceptance

- **Customers:** Authorized users can search, add, and edit customers. Administrators can view active and inactive records and restore soft-deleted customers; ordinary users see active records only. Deletion is blocked while active child records exist.
- **Products:** Authorized users can search, add, and edit products. Products can be soft-deleted and restored by permitted administrators; deletion is blocked while active price-history or sales-detail records exist.
- **Price history:** Authorized users can add, edit, and delete price entries according to their rights. A future-effective entry does not become the current price until its effective date.
- **Current price:** Show the latest active price effective on or before the requested date; show no current price when no such entry exists.
- **Quality:** Enforce permissions server-side, preserve data integrity, and record test outcomes and defects separately from implementation completion.

## Evidence board

“Merged” below means the corresponding pull request is present as a merge in the local repository history. It confirms integration, not that every acceptance check passed or that the system was released.

| Workstream | Evidence status | Pull request evidence |
|---|---|---|
| Customer/Product database views and indexes | Merged | [#75](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/75), [#80](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/80) |
| Current-price query, validation, delete guards, and demo data | Merged | [#76](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/76), [#77](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/77), [#78](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/78), [#79](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/79) |
| Customer module implementation | Merged | [#81](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/81) |
| Product module implementation | Merged | [#82](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/82) |
| Price-history current marker and permission-matrix work | Merged | [#84](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/84) |
| Customer, Product, and Price History wireframes, handoff, and states | Merged | [#70](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/70), [#71](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/71), [#72](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/72), [#73](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/73) |
| Sprint 2 usability review and design follow-ups | Merged | [#93](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/93), [#97](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/97), [#98](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/98) |
| Test specifications and acceptance references | Documentation available; execution result not asserted here | [Customer and Sprint 1 acceptance checks](../testing/s2-bld-01-customers-sprint1.md), [Products module acceptance checks](../testing/s2-bld-02-products-module.md), [Price-history and permissions checks](../testing/s2-permissions.md) |
| Sprint 2 planning notes and board | This document prepared; merge status depends on its PR | This document |

## Planning and review notes

- Use the team’s issue and pull-request board as the operational source of task ownership and current status; do not treat this summary as a replacement for it.
- Link each implementation or documentation PR to its task. Review the diff and relevant checks before merging.
- Track verification separately from implementation. A merged PR is not, by itself, evidence that all acceptance criteria passed.
- Record any remaining defects, unverified behaviors, or carryover explicitly during review.
- Revisit prioritization and responsibilities with the team as needed; this document makes no claim about the original calendar schedule or current individual task assignments.

## Related project records

- [Sprint 1 board and eight-week module plan](SPRINT_1_BOARD_AND_8_WEEK_MODULE_PLAN.md)
- [Team working agreement and Definition of Done](TEAM_WORKING_AGREEMENT_DEFINITION_OF_DONE_ROLE_GUIDE.md)
- [Sprint 1 review and retrospective](SPRINT_1_REVIEW_AND_RETROSPECTIVE_REPORT.md)
- [Sprint 1 retrospective action follow-up](SPRINT_2_RETRO_ACTION_FOLLOW_UP.md)
