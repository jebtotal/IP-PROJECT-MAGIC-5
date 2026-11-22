# Sprint 2 Velocity and Burndown

## Measurement update

No numerical Sprint 2 velocity or burndown is reported here. The available records do not provide a reliable Sprint 2 measurement baseline:

- The external task plan contains task IDs, due-day values, and statuses, but no estimates or agreed velocity unit. Its dates and status column are out of date.
- Merged PRs provide integration evidence, but do not by themselves establish that work met its acceptance criteria or was accepted as done.
- The reviewed Scrum/testing records do not include a sequence of remaining-work snapshots from which to construct a burndown.

Calculating a number from the stale status column or counting PRs as completed work would be misleading.

## Evidence available

The [Sprint 2 planning notes and evidence board](SPRINT_2_PLANNING_NOTES_AND_BOARD.md) records merged PR evidence for the database foundations, Customer and Product workflows, price history, and design work. The [mid-sprint check and impediment log](MID_SPRINT_2_CHECK_AND_IMPEDIMENT_LOG.md) notes that acceptance specifications and SQL test scripts exist, but that test execution results were not established by the reviewed records.

These artifacts support a summary of integrated work; they do not supply a valid velocity or burndown series.

## Metric definitions

- **Velocity:** Sum of the agreed estimates for work accepted as done during a defined sprint. Do not count merged PRs unless their linked work meets the agreed Definition of Done.
- **Burndown:** Remaining estimated work at each agreed checkpoint, measured against one fixed scope baseline. Keep the estimation unit consistent and record scope changes rather than silently changing the baseline.

## Capture table for an agreed tracking cycle

Fill this in only after the team selects the scope baseline, estimation method, and checkpoint cadence. Checkpoint labels can be the team's chosen sequence; no obsolete sprint dates are implied here.

| Checkpoint | Baseline work remaining (agreed units) | Accepted completed work (agreed units) | Remaining work (agreed units) | Evidence / scope changes |
|---|---:|---:|---:|---|
| Baseline | — | — | — | Confirm scope and estimation unit |
| Progress check | — | — | — | Record accepted work and changes |
| Close-out | — | — | — | Reconcile accepted work and carryover |

| Metric | Result | Basis |
|---|---|---|
| Sprint 2 velocity | Not calculable from the reviewed records | No agreed estimation unit or verified accepted-work totals |
| Sprint 2 burndown | Not calculable from the reviewed records | No reliable baseline and checkpoint history |

## Next measurement steps

1. Confirm the current team board and the work items included in the measurement scope.
2. Agree one estimate unit (or explicitly choose a task-count measure) and define when an item qualifies as done.
3. Capture remaining scope at consistent team-selected checkpoints and record accepted completions against linked issues/PRs and verification evidence.
4. At close-out, calculate velocity from accepted work only and summarize the remaining-work series, including scope changes and carryover.

