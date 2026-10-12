# Working on the Ruby application

The Rails app lives in `src/` and is developed and run exclusively through
Docker Compose. Ruby, Bundler, and gems are not installed on the host — every
Ruby/Rails command must run inside the `app` service container.

Run all Docker Compose commands from the repo root, where `docker-compose.yml`
and `.env` live; the compose service mounts `./src` into the container.

## Run the app

```
docker compose up
```

## Run the test suite

```
docker compose run --rm -e RAILS_ENV=test app bundle exec rails test
```

## Run RuboCop

```
docker compose run --rm app bundle exec rubocop
docker compose run --rm app bundle exec rubocop --auto-correct
```

## Install or update gems

The Dockerfile bakes `bundle install` into the image, so a `Gemfile` change
that breaks the existing `Gemfile.lock` (e.g. bumping `rails`) will fail the
build. Regenerate the lockfile **before** rebuilding:

1. Make sure the image is already built against the *old* Gemfile/Gemfile.lock
   pair. On a fresh checkout this means `docker compose build app` first,
   *before* editing the Gemfile.
2. Edit `Gemfile`.
3. Regenerate the lockfile from inside the container — the `./src:/app` bind
   mount means bundler reads the host's edited `Gemfile` and writes the new
   `Gemfile.lock` back to the host:

   ```
   docker compose run --rm app bundle lock --update=<gem> [<gem>...]
   ```

   Pass every gem that needs to move (for a Rails minor bump that's `rails`
   plus all rails component gems with `=` pins, plus tightly-constrained
   transitives like `arel` and `minitest`). `bundle lock` only resolves and
   writes the lockfile — it doesn't install. For broader updates use
   `bundle update <gem>...`.
4. Rebuild the image so the new gems get baked in:

   ```
   docker compose build app
   ```

A Ruby version bump (changing `ruby` in the `Gemfile` and the Dockerfile's
base image) can't use the old image for step 3: its Ruby rejects gems that need
the new Ruby. Regenerate the lockfile in a plain container of the new Ruby,
with the Bundler version from the Dockerfile, then rebuild as in step 4:

```
docker run --rm -v "$PWD/src:/app" -w /app ruby:<new>-alpine \
  sh -c 'gem install bundler -v <bundler> --no-document && bundle _<bundler>_ lock --update'
```

For other ad-hoc bundler commands:

```
docker compose run --rm app bundle <command>
```

## Run database migrations / rake tasks

```
docker compose run --rm app bundle exec rails db:migrate
docker compose run --rm app rake <task>
```

For the test database use `-e RAILS_ENV=test`.

## Rails console / one-off commands

```
docker compose run --rm app bin/rails console
docker compose run --rm app <any command>
```

## Don't

- Don't run `bundle`, `rake`, `rails`, `rspec`, `rubocop`, or any Ruby tooling
  directly on the host — the host has no compatible Ruby toolchain.
- Don't hand-edit `Gemfile.lock`; regenerate it via `bundle lock` inside the
  container as described above.
- Don't expect `docker compose build app` to fix an out-of-sync `Gemfile.lock`
  — the bake step runs `bundle install`, which errors on Gemfile/lockfile
  conflicts instead of resolving them.


# Infrastructure: `iac/server` and `iac/app`

Two OpenTofu root modules, each with its own state:

- `iac/server/main.tf` provisions the cloud resources (Hetzner VM, Cloudflare
  tunnels, AWS SES/IAM/ECR, GitHub Actions secrets).
  `.github/workflows/server.yml` plans it on master and applies it on release
  tags that change `iac/server` or `mise.toml`. Bootstrapping, and fixing a
  bad apply that locks CI out, are still done locally with
  `AWS_PROFILE=doedensonline`. The server apply and the prod deploy start on
  the same tag in no particular order: release an infra change that the app
  depends on (e.g. a new `PROD_*` secret) in an earlier tag.
- `iac/app/main.tf` deploys everything that runs on the host: the app
  container, its state directories and SQLite file, migrations and seeding,
  and the environment's `cloudflared` tunnel container (kreuzwerker/docker
  provider, one OpenTofu workspace per environment). The `deploy` job in
  `.github/workflows/ci.yml` applies it. Change per-environment deploy
  settings (`RAILS_ENV`, ports, mounts, env vars) there.

How the host is set up:

- **cloud-init (`hcloud_server.user_data`) only runs on first boot.** It's in
  `ignore_changes`, because changing it would replace the server and wipe the
  app state in `/app-state`. A change there doesn't reach the existing server;
  apply it by hand over SSH as well.
- **Docker log rotation is per container, not daemon-wide.** Every
  `docker_container` in `iac/app` sets `log_driver = "json-file"` and
  `local.log_opts`; set them on new containers too.
- **The host holds no registry credentials.** `iac/app` passes ECR
  credentials along with each pull through the provider's `registry_auth`.
