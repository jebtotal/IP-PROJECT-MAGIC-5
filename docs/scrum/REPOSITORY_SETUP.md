# Repository Setup

This guide covers the GitHub settings and templates for team contributions. Templates are stored in `.github`; branch protection must be enabled in the repository's GitHub settings.

## Protect the `main` branch

A repository admin can configure this in GitHub:

1. Open the repository **Settings**.
2. Go to **Branches** (or **Rules > Rulesets**, depending on the GitHub interface).
3. Add a branch protection rule or ruleset targeting `main`.
4. Require changes to be proposed through a pull request.
5. Require at least one teammate approval before merging.
6. Require approval of the most recent reviewable push, and dismiss stale approvals when new commits are pushed.
7. Block force pushes and branch deletion.
8. Save the rule and confirm it applies to `main`.

If GitHub Actions checks are available, admins can also require the relevant checks to pass before merging. Do not select required checks until the workflows exist and have reported checks to GitHub.

## Pull requests and issues

- `.github/PULL_REQUEST_TEMPLATE.md` prompts contributors to summarize changes, link a task, explain verification, and check important project requirements.
- `.github/ISSUE_TEMPLATE/bug_report.yml` collects reproduction steps and expected behavior for bugs.
- `.github/ISSUE_TEMPLATE/feature_request.yml` collects the user need, proposed solution, and acceptance criteria for feature requests.

Use the pull request template for focused changes and link the related issue when one exists. Keep issue titles and acceptance criteria specific enough to plan and verify the work.
