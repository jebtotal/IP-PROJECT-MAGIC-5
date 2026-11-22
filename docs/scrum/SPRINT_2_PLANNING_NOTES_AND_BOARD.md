# Sprint 2 Planning Notes and Board

## Planning baseline

- **Sprint:** 2 (planned for Weeks 3–4; ten sprint days)
- **Planning date:** Confirm with the team
- **Sprint goal:** Deliver permission-checked Customer and Product management, including effective-dated price history, and verify the flows with focused acceptance, authorization, and regression tests.
- **Scope source:** [Sprint 1 board and eight-week module plan](SPRINT_1_BOARD_AND_8_WEEK_MODULE_PLAN.md) and the Sprint 2 task breakdown.
- **Schedule:** Due days below are relative sprint days from the task breakdown, not calendar dates.

The task breakdown is maintained outside this repository. Its statuses are reproduced below as a **source-plan snapshot**, not verified live GitHub issue or PR status. Reconcile every status, owner, due day, and link with the team board before treating this as the current board. No velocity or capacity figure is assumed.

## Sprint outcome and acceptance

The sprint meets its goal when:

1. **Customers:** Authorized users can list, search, add, and edit customers. Administrators can view Active/Inactive/All and restore records; ordinary Users see active records only. Soft delete is not permanent, and deletion is blocked when active child records exist.
2. **Products:** Authorized users can list, search, add, edit, and soft-delete products; permitted administrators can restore them. Product deletion is blocked when active price-history or sales-detail records reference the product.
3. **Price history:** Authorized users can add, edit, and delete price-history entries according to their rights. Future-effective prices may be entered, but the displayed current price is the latest active price effective on or before today.
4. **Authorization and data integrity:** Each action is checked server-side as well as reflected in the UI. Validation, active views, delete guards, and database behavior match the accepted requirements.
5. **Verification:** Customer and Product/Price History acceptance checks are run, permission behavior is exercised, defects are recorded and retested, and the agreed Sprint 1 regression checks are completed or explicitly carried over.

Related test references:

- [Customer and Sprint 1 acceptance checks](../testing/s2-bld-01-customers-sprint1.md)
- [Products module acceptance checks](../testing/s2-bld-02-products-module.md)
- [Price history gaps, current price, and permissions](../testing/s2-permissions.md)

## Planning notes and decisions to confirm

- Start with Customer work, then Product and Price History work, while the DB Admin and UI/UX Designer deliver prerequisites and handoffs in parallel.
- Confirm on Day 1 whether unfinished Sprint 1 tests are release-blocking. Track any carryover explicitly; do not silently add it to the Sprint 2 commitment. Sprint 2 includes a planned Sprint 1 regression task.
- Confirm the current state of each planned task against its issue, PR, and test evidence. A merged PR alone does not satisfy the Definition of Done.
- Keep each planned PR linked to its task. Use the existing Definition of Done: criteria met, relevant checks run, peer review approved, PR merged, and follow-up limitations recorded.
- The task breakdown assigns the named owners below. Confirm their availability and due-day commitments with the team; raise any capacity conflict or dependency risk early.

## Dependencies and risks

| Dependency or risk | Impact | Planning response |
|---|---|---|
| Customer/Product active views and indexes (S2-DBA-01) | List, filters, and search rely on the correct active-record behavior. | Verify migration and view behavior before accepting the list tasks. |
| Current-price query (S2-DBA-02) | Product current-price display and price-history behavior depend on effective-date selection. | Verify the query with no price, a past price, and a future price before UI acceptance. |
| Validation constraints and child-record delete checks (S2-DBA-03/04) | Forms and soft-delete flows can otherwise accept invalid data or orphan active references. | Agree API/database error behavior with the Developer and Tester before marking lifecycle tasks done. |
| Design handoffs are due after some implementation tasks begin. | Late wireframes or unresolved proposed UI details can cause rework. | Hand off the Customer wireframe first; confirm any Product/Price History details that differ from the accepted requirements before implementation relies on them. |
| Sprint 1 testing was unfinished in the retrospective snapshot. | Regressions or account/permission defects may affect Sprint 2 verification. | Decide the carryover priority on Day 1 and review regression results before Sprint Review. |
| Many tasks are scheduled across the same ten-day sprint, with no velocity baseline recorded here. | The planned due days may exceed available capacity. | Review progress and impediments at the midpoint; re-scope or reassign openly rather than silently moving unfinished work to Done. |

## Board

Statuses below reflect the task breakdown snapshot only. Update them from the live team board and link each task to its issue/PR. The source plan lists S2-DEV tasks as In progress, S2-DBA tasks as Merged, and S2-TST/S2-UIX/S2-SM tasks as Not started; those values have not been independently confirmed here.

| ID | Due day | Owner | Task | Source-plan status |
|---|---:|---|---|---|
| S2-DEV-01 | 2 | Developer — Dan Weslet Cabellero | Customer list with search and permission-checked filters | In progress — verify |
| S2-DEV-02 | 3 | Developer — Dan Weslet Cabellero | Customer create and edit form | In progress — verify |
| S2-DEV-03 | 4 | Developer — Dan Weslet Cabellero | Customer soft delete and restore | In progress — verify |
| S2-DEV-04 | 5 | Developer — Dan Weslet Cabellero | Product list with search and filters | In progress — verify |
| S2-DEV-05 | 6 | Developer — Dan Weslet Cabellero | Product create and edit form | In progress — verify |
| S2-DEV-06 | 7 | Developer — Dan Weslet Cabellero | Product soft delete and restore | In progress — verify |
| S2-DEV-07 | 8 | Developer — Dan Weslet Cabellero | Add, edit, and delete effective-dated prices | In progress — verify |
| S2-DEV-08 | 9 | Developer — Dan Weslet Cabellero | Current-price display and per-action rights checks | In progress — verify |
| S2-DBA-01 | 2 | DB Admin — Sedric Pineda | Customer/Product active views and indexes | Merged — verify |
| S2-DBA-02 | 4 | DB Admin — Sedric Pineda | Current price as of a given date | Merged — verify |
| S2-DBA-03 | 5 | DB Admin — Sedric Pineda | Validation constraints for payment terms and units | Merged — verify |
| S2-DBA-04 | 6 | DB Admin — Sedric Pineda | Verify Customer/Product child-record delete checks | Merged — verify |
| S2-DBA-05 | 7 | DB Admin — Sedric Pineda | Customer, Product, and price-history demo data | Merged — verify |
| S2-DBA-06 | 9 | DB Admin — Sedric Pineda | Search performance check and index tuning | Merged — verify |
| S2-TST-01 | 3 | Tester — Kent Genesis Makiramdam | Customer module test cases | Not started — verify |
| S2-TST-02 | 5 | Tester — Kent Genesis Makiramdam | Product and Price History test cases | Not started — verify |
| S2-TST-03 | 7 | Tester — Kent Genesis Makiramdam | Soft-delete/restore and active-child blocking tests | Not started — verify |
| S2-TST-04 | 8 | Tester — Kent Genesis Makiramdam | Customer/Product/Price History per-right tests | Not started — verify |
| S2-TST-05 | 9 | Tester — Kent Genesis Makiramdam | Sprint 1 regression tests | Not started — verify |
| S2-TST-06 | 9 | Tester — Kent Genesis Makiramdam | Bug reports and fix verification | Not started — verify |
| S2-UIX-01 | 2 | UI/UX Designer — Bea Bocobo | Customer screen wireframes | Not started — verify |
| S2-UIX-02 | 3 | UI/UX Designer — Bea Bocobo | Product and Price History wireframes | Not started — verify |
| S2-UIX-03 | 5 | UI/UX Designer — Bea Bocobo | Hi-fi mockups and developer handoff notes | Not started — verify |
| S2-UIX-04 | 7 | UI/UX Designer — Bea Bocobo | Empty, error, and confirm-delete states | Not started — verify |
| S2-UIX-05 | 9 | UI/UX Designer — Bea Bocobo | Usability review of built screens | Not started — verify |
| S2-SM-01 | 1 | Scrum Master — Jahreb Total | Sprint 2 planning notes and board | Draft prepared — confirm with team |
| S2-SM-02 | 3 | Scrum Master — Jahreb Total | Follow up Sprint 1 retrospective actions | Not started — verify |
| S2-SM-03 | 5 | Scrum Master — Jahreb Total | Mid-sprint check and impediment log | Not started — verify |
| S2-SM-04 | 8 | Scrum Master — Jahreb Total | Update velocity and burndown | Not started — verify |
| S2-SM-05 | 10 | Scrum Master — Jahreb Total | Sprint 2 review and retrospective report | Not started — verify |

## Scrum Master checkpoints

- **Day 1 — Planning:** Confirm sprint goal, capacity, owners, dates, carryover decision, task links, and the live starting status.
- **Day 3 — Follow-up:** Review Sprint 1 retrospective actions and confirm dependencies are not blocking implementation.
- **Day 5 — Mid-sprint:** Update the impediment log; check scope, risks, and task status against evidence.
- **Day 8 — Forecast:** Update velocity/burndown from actual completed work and forecast remaining tasks.
- **Day 10 — Review and retrospective:** Demonstrate outcomes against the acceptance criteria, record incomplete work and defects honestly, and agree on improvement actions.
