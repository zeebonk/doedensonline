---
name: plan-rails-upgrade
description: Plan the upgrade of the Rails app in src/ to the next Rails minor version (latest patch), including matching Ruby and dependency upgrades, and file the plan as a GitHub issue. A paper exercise based on release notes and the codebase; it doesn't build or run anything.
---

Create a plan for upgrading Rails to the next minor version (latest patch).

Review the release notes of intermediate versions for any required/useful changes.

Include, when relevant:
- Upgrade of Ruby to best matching version for the target version of rails
- Upgrade of all dependencies to best matching versions for the target version of rails

Put the plan in a Github issue.

## Paper exercise only

Base the plan on two things: the published docs (release notes, upgrade guides, gem CHANGELOGs, RubyGems metadata) and a read-through of the codebase. Fix whatever issues those don't reveal while executing the plan, not while planning it.

- Allowed: reading and grepping the repo, fetching docs, querying the RubyGems API.
- Not allowed: building images, running containers, running `bundle`, running tests, copying `src/` into a scratch copy, or editing any files in the repo.
- If you can't settle something on paper (e.g. whether the lockfile resolves, or whether a gem's behaviour change affects us), don't try it out. List it under **Open questions / verify during execution**: say what to check and what to do for each outcome.

## Notes from previous runs

- Earlier plans to use as a structure reference: #154 (4.1 → 4.2) and #196 (5.0 → 5.1). Leave out #196's "Validation spike" section. Plans no longer include a spike.
- The plan's execution steps must follow the Docker-only workflow in `CLAUDE.md`. There is no Ruby on the host.
- To find the newest gem version that still supports the app's Ruby, `curl` the RubyGems API (`/api/v1/versions/<gem>.json`, field `ruby_version`) and read the requirements. Don't start a container to evaluate them.
