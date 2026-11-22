# Sprint 3 Mid-Sprint Check and Impediment Log

## Purpose and evidence basis

This date-free check summarizes the Sprint 3 Human Resources evidence available in the repository. It is not minutes of a confirmed meeting or a live issue-board export. Outdated task-plan dates and status cells are not used as current progress.

Merged PRs establish integration only, not acceptance-test completion. The Sales-versus-Sprint-3 scope discrepancy is still a planning decision for the team.

## Progress snapshot

| Workstream | Evidence found | Evidence-based status |
|---|---|---|
| HR database foundations | PRs [#65](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/65)–[#69](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/69) and [#74](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/74) cover employee current job/department, job-history date uniqueness, profile linkage, child-delete checks, demo data, and indexes/backup. | Integrated; runtime verification is not established by merge history alone. |
| HR application | PRs [#86](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/86), [#88](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/88), and [#90](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/90)–[#92](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/92) cover job and employee workflows, job history/profile, and View Job History access. | Integrated; acceptance-test results are not established here. |
| HR design | PRs [#99](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/99), [#105](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/105)–[#110](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/110), [#112](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/112), and [#117](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/117) cover wireframes, privacy/status guidance, timeline, mockups, usability review, and follow-ups. | Design artifacts integrated. |
| HR testing | Five HR SQL test scripts are present under `my-web-app/supabase/tests/`. | Test assets exist; a consolidated HR acceptance run and pass/fail report were not found in the reviewed Scrum/testing documents. |
| Sprint 2 carryover | The [carryover prioritization](SPRINT_3_CARRYOVER_PRIORITIZATION.md) identifies missing test evidence as conditional pending live-board/Tester confirmation. | No specific carryover is team-confirmed by the reviewed records. |

## Impediment and follow-up log

These are planning, tracking, and evidence gaps—not claims of confirmed software defects. No technical blocker is confirmed by the evidence reviewed.

| ID | Risk or impediment | Impact | Follow-up | Suggested coordinator | Status |
|---|---|---|---|---|---|
| S3-IMP-01 | Sprint 3 Sales scope conflicts between the eight-week overview and detailed task plan. | Scope and capacity cannot be treated as settled. | Confirm Sales placement and reconcile both planning sources; keep it outside the working baseline until the team decides. | Scrum Master | Open — team decision needed |
| S3-IMP-02 | HR SQL tests exist, but consolidated end-to-end/permission test outcomes are not recorded in the reviewed docs. | HR acceptance and sensitive salary/job-history access are not verified by the available evidence. | Tester records test build/environment, granted and denied cases, pass/fail/blocked outcomes, defects, and retests; involve Developer/DB Admin for failures. | Tester | Open — execution evidence needed |
| S3-IMP-03 | Sprint 2 testing carryover is conditional; current task-plan statuses cannot confirm whether those checks remain open. | Sprint 3 regression scope could be duplicated or missed. | Reconcile with Tester and live board, then update the existing Sprint 1–2 regression task or create only the confirmed missing work. | Scrum Master and Tester | Open — live status not verified |
| S3-IMP-04 | External plan dates/statuses are stale and velocity has no reliable baseline. | The task sheet cannot be used to forecast current progress. | Use the live board for ownership/status; do not infer completion or capacity from the stale task plan. | Scrum Master | Tracking gap documented; live board not verified |

## Check-in decisions needed

1. Confirm whether Sales is in Sprint 3 or Sprint 4.
2. Verify actual HR test execution, including both allowed and denied access to job history and salary.
3. Confirm whether any Sprint 2 acceptance tests or defects remain open and prioritize only those items.
4. Reconcile ownership and status with the live team board; keep merged, tested, and accepted distinct.

These are follow-up prompts, not decisions attributed to a meeting.

## Related records

- [Sprint 3 planning notes and board](SPRINT_3_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 3 carryover prioritization](SPRINT_3_CARRYOVER_PRIORITIZATION.md)
- [Sprint 2 review and retrospective](SPRINT_2_REVIEW_AND_RETROSPECTIVE_REPORT.md)
- [Team working agreement and Definition of Done](TEAM_WORKING_AGREEMENT_DEFINITION_OF_DONE_ROLE_GUIDE.md)

