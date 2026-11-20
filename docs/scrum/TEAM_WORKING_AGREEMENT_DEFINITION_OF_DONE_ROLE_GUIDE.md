# Team Working Agreement, Definition of Done, and Role Guide

This guide describes how the team works together on the ERP project, which includes authentication, user management, and Supabase database features. The team can revisit and update this agreement at sprint planning or retrospective.

## Team Working Agreement

- Keep sprint tasks and progress visible on the team's GitHub board.
- Give each task a clear owner, expected result, and due sprint day. Ask for clarification when a task is unclear.
- Work on a feature branch and use a pull request (PR) to propose changes; do not commit directly to `main`.
- Link each PR to its task. Keep PRs focused, explain what changed, and mention how it was checked.
- Review teammates' work respectfully and address review feedback before merging.
- Share progress at check-ins. Raise blockers as soon as they may affect a task, and agree on who will help and what happens next.
- If a due date is at risk, tell the team early and agree whether to adjust scope, get help, or change the date.
- Communicate respectfully, listen to each role's concerns, and make team decisions visible.

## Definition of Done

A task is done when the relevant items below are complete:

- The agreed task requirements and acceptance criteria are met.
- The change is implemented in the correct feature branch and is linked to its issue or sprint task.
- Relevant tests or checks have been run, and failures have been fixed or clearly reported.
- The change has been reviewed and approved by a teammate before it is merged.
- The PR is merged into the team's target branch.
- Related documentation, setup steps, or user instructions are updated when needed.
- Any known follow-up work or limitation is recorded on the task.


## Role Guide

| Role | Main responsibilities | Coordinate with |
|---|---|---|
| **Scrum Master — Jahreb Total** | Facilitate sprint planning and check-ins, help the team resolve impediments, and support clear communication. | The whole team |
| **Developer — Dan Weslet Cabellero** | Implement application features such as registration, login, password recovery, user management, permissions, and the main page. Link code PRs to tasks and respond to reviews. | DB Admin on data needs; UI/UX Designer on screens; Tester on behavior and fixes |
| **DB Admin — Sedric Pineda** | Maintain the Supabase schema, migrations, seed/setup data, and database documentation. Check data integrity and RLS policies for database changes. | Developer on application data needs; Tester on database verification |
| **UI/UX Designer — Bea Bocobo** | Prepare the design system, wireframes, and mockups; review implemented screens for usability and share actionable feedback. | Developer on implementation; Tester on usability issues |
| **Tester — Kent Genesis Makiramdam** | Define acceptance criteria and test cases; verify key flows such as registration, authentication, user management, and permissions; report bugs and retest fixes. | Developer on defects; DB Admin on data-related issues; Scrum Master on test progress and blockers |
