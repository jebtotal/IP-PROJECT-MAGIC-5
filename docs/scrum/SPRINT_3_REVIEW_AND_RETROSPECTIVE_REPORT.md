# Sprint 3 Review and Retrospective

## Purpose and evidence basis

This is a date-free, evidence-based review of the Human Resources scope in the Sprint 3 plan. It summarizes merged PRs and repository artifacts; it is not minutes of a confirmed Sprint Review or a substitute for team feedback. The original task-plan dates and status cells are not treated as current.

Merged PRs establish integration, not acceptance-test completion or release readiness.

## Sprint outcome

| Area | Evidence reviewed | Evidence-based result |
|---|---|---|
| HR database foundations | PRs [#65](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/65)–[#69](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/69) and [#74](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/74) | Current-job/department query, job-history date uniqueness, profile link, child-delete checks, demo data, and indexes/backup changes are integrated. |
| HR application | PRs [#86](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/86), [#88](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/88), and [#90](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/90)–[#92](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/92) | Job/employee workflows, job history/profile, and View Job History access work are integrated. |
| HR design | PRs [#99](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/99), [#105](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/105)–[#110](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/110), [#112](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/112), and [#117](https://github.com/jebtotal/IP-PROJECT-MAGIC-5/pull/117) | Wireframes, privacy/status guidance, timeline design, mockups, usability review, and follow-ups are integrated. |
| Testing and acceptance | Five HR SQL test scripts are present under `my-web-app/supabase/tests/`. | Test assets exist, but the reviewed Scrum/testing documents do not establish a consolidated HR acceptance run, pass/fail results, defect retests, or sign-off. |
| Sales scope | The eight-week overview includes Sales in Sprint 3; the detailed per-member plan places Sales in Sprint 4. | Scope discrepancy remains for the team to resolve; no Sprint 3 Sales commitment is inferred. |

**Overall:** HR implementation and design evidence is present in merged PRs. The available records do not establish that all HR acceptance criteria passed or that the Sprint 3 outcome is release-ready.

## Review discussion points

- Demonstrate Department, Job, and Employee flows against the agreed acceptance criteria.
- Verify job-history effective dates, current-job/department selection, and child-record delete guards.
- Demonstrate both granted and denied access to job history and salary through the UI and server/API paths.
- Review actual HR test-run evidence, defects, and retests before accepting the scope.
- Resolve whether Sales belongs to Sprint 3 or Sprint 4 and update the planning sources consistently.
- Confirm accepted work and any carryover using the live team board.

These are review prompts, not claims that a demonstration or team decision has already occurred.

## Retrospective observations

These observations are drawn from repository evidence, not from individual team feedback.

### What appears to have gone well

- HR database foundations, application work, and design artifacts were integrated through focused PRs.
- The repository includes database test scripts for core HR data rules.
- The project explicitly identifies the View Job History right for sensitive job-history and salary visibility.

### What should improve

- Record end-to-end HR and permission test results, including denied-access cases, defects, and retests; test scripts alone do not show outcomes.
- Reconcile the Sales scope difference between the overview and detailed task plan.
- Keep external task-plan dates/statuses distinct from the current live board.
- Agree on an estimation unit and capture accepted-work snapshots before reporting velocity; the available records do not support a Sprint 3 velocity figure.

## Proposed follow-up actions

| Action | Suggested coordinator | Completion evidence |
|---|---|---|
| Confirm Sales placement and reconcile the planning sources. | Scrum Master and team | Team-confirmed scope reflected consistently in planning records. |
| Record HR acceptance and privacy/permission test runs, defects, and retests. | Tester, with Developer and DB Admin for fixes | Linked test report with build/environment and pass/fail/blocked outcomes. |
| Reconcile Sprint 2 carryover and HR completion against the live board. | Scrum Master and Tester | Current board links open work to owners, PRs, and verification evidence. |
| Establish an agreed measurement method for future forecasting. | Scrum Master and team | Team-selected estimate unit and checkpoint records; see [Sprint 3 velocity and Sprint 4 risk register](SPRINT_3_VELOCITY_AND_SPRINT_4_RISK_REGISTER.md). |

These are proposed actions for team confirmation, not assigned commitments.

## Related records

- [Sprint 3 planning notes and board](SPRINT_3_PLANNING_NOTES_AND_BOARD.md)
- [Sprint 3 mid-sprint check and impediment log](MID_SPRINT_3_CHECK_AND_IMPEDIMENT_LOG.md)
- [Sprint 3 carryover prioritization](SPRINT_3_CARRYOVER_PRIORITIZATION.md)
- [Sprint 3 velocity and Sprint 4 risk register](SPRINT_3_VELOCITY_AND_SPRINT_4_RISK_REGISTER.md)
- [Team working agreement and Definition of Done](TEAM_WORKING_AGREEMENT_DEFINITION_OF_DONE_ROLE_GUIDE.md)

