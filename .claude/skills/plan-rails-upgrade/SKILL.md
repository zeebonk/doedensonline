---
name: plan-rails-upgrade
description: Plan the upgrade of the Rails app in src/ to the next Rails minor version (latest patch), including matching Ruby and dependency upgrades, and file the plan as a GitHub issue.
---

Create a plan for upgrading Rails to the next minor version (latest patch).

Review the release notes of intermediate versions for any required/useful changes.

Include, when relevant:
- Upgrade of Ruby to best matching version for the target version of rails
- Upgrade of all dependencies to best matching versions for the target version of rails

Put the plan in a Github issue.

## Notes from previous runs

- Earlier plans to use as a structure reference: #154 (4.1 → 4.2) and #196 (5.0 → 5.1).
- Follow the Docker-only workflow in `CLAUDE.md`. There is no Ruby on the host.
- Validate the plan with a throwaway spike before filing it. Copy `src/` into `.context/`, build it under a separate image tag (not the compose `latest` tag), run `bundle lock --update` with the candidate Gemfile, then run the tests, RuboCop, i18n-tasks, and a production eager-load/Puma boot. Report the results in the issue.
- To find the newest gem version that still supports the app's Ruby, query the RubyGems API (`/api/v1/versions/<gem>.json`, field `ruby_version`). Run the query from inside a `ruby:<version>` container so you can use `Gem::Requirement`.
