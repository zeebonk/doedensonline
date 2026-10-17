# DoedensOnline

The website of the Doedens family. A Rails app in `src/`, deployed with
OpenTofu from `iac/`. `README.md` explains how to run it locally.


# Tasks

Every day-to-day operation is a mise task in `mise.toml`, and CI runs the
same tasks. `mise tasks` lists them; `mise run <task> --help` shows the
arguments of a task.

- `app:*` tasks work on the Rails app, `server:*` on `iac/server` and
  `deployment:*` on `iac/app`.
- Use a task, not the command it wraps. Tasks run with mise's pinned tools
  first on the `PATH`; a bare `tofu` or `tflint` can be another version.
- Tasks append extra arguments to their last command, e.g.
  `mise run app:test test/models/user_test.rb`. Tasks with a `usage` spec
  take only the arguments they declare.
- When CI needs a new operation, add a task and call it from the workflow.
  CI-only concerns stay in the workflow: credentials, caches, job summaries,
  and settings like `TF_INPUT=false` or `TF_CLI_ARGS_apply=-auto-approve`.


# The Rails app

Ruby is not installed on the host. All Ruby runs in the `app` container of
Docker Compose. Run Docker Compose from the repo root, where
`docker-compose.yml` and `.env` live; the container mounts `./src` at `/app`.

For commands without a task:

```
docker compose run --rm app bin/rails console
docker compose run --rm app bin/rails db:migrate
docker compose run --rm app <command>
```

Add `-e RAILS_ENV=test` to use the test database.

## Update gems

The Dockerfile bakes `bundle install` into the image. A `Gemfile` change
that conflicts with `Gemfile.lock` (e.g. a `rails` bump) breaks the build,
so regenerate the lockfile first:

1. Build the image against the old `Gemfile` and `Gemfile.lock`. On a fresh
   checkout, run `docker compose build app` before you edit the `Gemfile`.
2. Edit the `Gemfile`.
3. Regenerate the lockfile in the container. The bind mount makes bundler
   read the edited `Gemfile` and write `Gemfile.lock` back to the host:

   ```
   docker compose run --rm app bundle lock --update=<gem> [<gem>...]
   ```

   Pass every gem that moves. For a Rails minor bump that is `rails`, every
   Rails component gem with an `=` pin, and tight transitives like `arel`
   and `minitest`. `bundle lock` only writes the lockfile; for broader
   updates use `bundle update <gem>...`.
4. Rebuild the image: `docker compose build app`.

A Ruby bump (the `ruby` line in the `Gemfile` and the Dockerfile's base
image) can't use the old image in step 3, because its Ruby rejects gems that
need the new one. Regenerate the lockfile in a plain container of the new
Ruby, with the Bundler version from the Dockerfile, then rebuild:

```
docker run --rm -v "$PWD/src:/app" -w /app ruby:<new>-alpine \
  sh -c 'gem install bundler -v <bundler> --no-document && bundle _<bundler>_ lock --update'
```

## Don't

- Don't run `bundle`, `rake`, `rails`, `rubocop` or other Ruby tools on the
  host.
- Don't hand-edit `Gemfile.lock`; regenerate it as above.
- Don't expect `docker compose build app` to fix an out-of-sync
  `Gemfile.lock`. Its `bundle install` fails on conflicts instead of
  resolving them.


# Infrastructure

`iac/` holds two OpenTofu root modules, each with its own state. Both lint
with `iac/.tflint.hcl`.

- `iac/server` provisions the cloud resources: the Hetzner VM, the
  Cloudflare zone and deploy token, AWS SES, IAM and ECR, and the `dev` and
  `prod` GitHub environments with their secrets. `.github/workflows/server.yml`
  runs `server:plan` on every pull request and `server:apply` on every push
  to `master`, drift included. Both wait for an approval on the `server`
  environment. Bootstrapping, and fixing a bad apply that locks CI out,
  happen locally with `AWS_PROFILE=doedensonline`.
- `iac/app` deploys one environment per OpenTofu workspace (`dev`, `prod`):
  its Cloudflare tunnel, ingress and DNS record, and everything on the host
  (the app container, its state directories and SQLite file, migrations and
  seeding, and the `cloudflared` container), through the kreuzwerker/docker
  provider. `main.tf` holds the per-environment settings. The `deploy` job
  in `.github/workflows/ci.yml` runs `deployment:apply`: pushes to `master`
  deploy to dev, GitHub Releases to prod.

The server apply and the dev deploy start on the same push to `master`, in
no particular order. Merge an infra change the app depends on (e.g. a new
deploy secret) first.

How the host works:

- **cloud-init (`hcloud_server.user_data`) only runs on first boot.** It is
  in `ignore_changes`, because a change would replace the server and wipe
  the app state in `/app-state`. To change the existing server, also apply
  the change by hand over SSH.
- **Docker log rotation is per container, not daemon-wide.** Every
  `docker_container` in `iac/app` sets `log_driver = "json-file"` and
  `local.log_opts`; new containers need them too.
- **The host holds no registry credentials.** `iac/app` passes ECR
  credentials with each pull through the provider's `registry_auth`.
