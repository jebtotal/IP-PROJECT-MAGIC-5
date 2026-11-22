# Sprint 3 Planning Notes and Board

## Purpose and evidence basis

This is a date-free planning record for the Human Resources workstream. It uses the detailed per-member task breakdown stored outside the project folder as the working scope baseline and records the conflict with the eight-week module overview below. It is not a live task tracker; merged PR evidence does not establish that acceptance tests passed.

## Scope decision to confirm

The [eight-week module plan](SPRINT_1_BOARD_AND_8_WEEK_MODULE_PLAN.md) places Human Resources and Sales in Sprint 3. The detailed per-member task plan places Human Resources tasks in Sprint 3 and Sales tasks in Sprint 4.

**Working baseline:** plan Human Resources for Sprint 3 and do not silently add Sales. Confirm the Sales placement with the team and reconcile the two source plans. This document does not claim that the team has made that decision.

## Sprint goal

Deliver the Human Resources workflows for Departments, Jobs, Employees, and effective-dated Job History, with appropriate data integrity and permission checks. Keep implementation, design, and verification evidence linked to the team’s current work board.

## Scope and acceptance

- **Departments and Jobs:** Authorized users can view and manage department/job records; deletion or deactivation respects active references.
- **Employees:** Authorized users can search and view employees, create and edit employee records, and manage inactive status and separation dates.
- **Job History:** Authorized users can record effective-dated assignments/promotions with salary and department/job references. Duplicate effective dates are rejected; the latest valid effective record determines the current job/department.
- **Employee profile:** The profile presents the employee and job-history timeline coherently.
- **Privacy and authorization:** Job-history and salary visibility follow the View Job History right, enforced server-side as well as in the UI.
- **Verification:** Department/job, employee lifecycle, job-history, privacy/permission, and applicable Sprint 1–2 regression checks have recorded outcomes. Test assets alone are not test results.

## Evidence board

The detailed task plan’s S3 status column is not used as current status. The table below reports only evidence found in repository history and test assets.

| Workstream | Planned focus | Evidence found | Evidence-based status |
|---|---|---|---|
| Database | Employee current-job/department query, unique job-history dates, profile-to-employee link, child-delete checks, HR demo data, indexes and backup/restore. | Merged PRs [#65](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/65)–[#69](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/69) and [#74](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/74). | Integrated; merge history alone does not establish runtime verification. |
| HR application | Department/job management, employee list/forms/lifecycle, job history, profile timeline, and View Job History authorization. | Merged PRs [#86](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/86), [#88](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/88), and [#90](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/90)–[#92](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/92). | Implementation evidence integrated; acceptance-test results are not established here. |
| UI/UX | Department/job and employee/profile wireframes, status/privacy guidance, timeline design, mockups, and usability review. | Merged PRs [#99](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/99), [#105](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/105)–[#110](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/110), [#112](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/112), and [#117](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/117). | Design artifacts and follow-ups integrated. |
| Testing | Department/job, employee, effective-date/salary, permission/privacy, regression, defect, and retest checks. | HR database test scripts exist under `my-web-app/supabase/tests/`. | Test assets exist; no consolidated HR acceptance run or pass/fail report was found in the reviewed Scrum/testing documents. |
| Sales scope | Sales headers/details, scheduled in Sprint 4 in the detailed task plan but Sprint 3 in the eight-week overview. | Conflicting planning records; no Sprint 3 commitment is inferred. | Team confirmation needed. |

## Dependencies and risks

| Risk or dependency | Planning response |
|---|---|
| Sales is assigned to different sprints in the two planning records. | Confirm the intended placement with the team and update the source plans consistently. Keep Sales out of the working baseline until then. |
| HR history depends on valid employee, job, and department references and effective-date rules. | Verify migration constraints and current-job queries with representative data before accepting the UI flow. |
| Salary and job-history access is sensitive. | Exercise both granted and denied access through the UI and direct server/API paths; record results and defects. |
| Sprint 2 follow-up/testing evidence may be incomplete. | Review the [Sprint 2 impediment log](MID_SPRINT_2_CHECK_AND_IMPEDIMENT_LOG.md) and [review report](SPRINT_2_REVIEW_AND_RETROSPECTIVE_REPORT.md); carry over only work the team confirms. |
| The external task-plan dates and statuses are stale, and no reliable velocity baseline is recorded. | Use the live team board for ownership/status. Do not infer completion from old status cells or calculate velocity from PR counts. |

## Planning and review notes

- Confirm scope, ownership, and current status against the live issue/PR board; this document does not reproduce outdated due days or status cells.
- Link each task to its implementation/design PR and to verification evidence where applicable.
- Review the Sprint 2 carryover before committing work, particularly unverified tests or defect retests.
- Treat “merged,” “tested,” and “accepted” as separate states under the existing Definition of Done.
- Record any decision about Sales scope in both planning sources so the discrepancy does not recur.

## Related records

- [Sprint 1 board and eight-week module plan](SPRINT_1_BOARD_AND_8_WEEK_MODULE_PLAN.md)
- [Team working agreement and Definition of Done](TEAM_WORKING_AGREEMENT_DEFINITION_OF_DONE_ROLE_GUIDE.md)
- [Sprint 2 planning notes and evidence board](SPRINT_2_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 2 review and retrospective](SPRINT_2_REVIEW_AND_RETROSPECTIVE_REPORT.md)
- [Sprint 2 carryover prioritization](SPRINT_3_CARRYOVER_PRIORITIZATION.md)
- [Sprint 3 mid-sprint check and impediment log](MID_SPRINT_3_CHECK_AND_IMPEDIMENT_LOG.md)
- [Sprint 3 velocity and Sprint 4 risk register](SPRINT_3_VELOCITY_AND_SPRINT_4_RISK_REGISTER.md)
- [HR database test scripts](../../my-web-app/supabase/tests/)

