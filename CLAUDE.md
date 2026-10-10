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
docker compose run --rm app script/console
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


# Infrastructure: Terraform → Ansible handoff

Terraform (`iac/server/main.tf`) provisions the cloud resources (Hetzner VMs,
Cloudflare tunnels, AWS SES/IAM, GitHub Actions secrets) **and** writes a
local `iac/server/inventory.yaml` via a `local_file` resource. This generated file is
the bridge between Terraform and Ansible:

- Terraform owns infra-level facts: server IPs, tunnel tokens, ECR access
  keys, the per-instance `instance` name.
- It serializes those facts into `iac/server/inventory.yaml` as a standard Ansible
  inventory with `prod` and `dev` groups.
- Ansible (`playbook.yaml`) then consumes that inventory to provision/converge
  the same VMs:

  ```
  cd iac/server
  uv run ansible-playbook -i inventory.yaml playbook.yaml -e target=prod
  ```

Implications:

- **`iac/server/inventory.yaml` is generated, not authored.** It is gitignored. Don't
  edit it by hand and don't commit it — changes will be overwritten on the
  next `tofu apply`. To change inventory contents, edit the `local_file
  "inventory"` block in `main.tf`.
- **It contains secrets** (ECR keys, Cloudflare tunnel tokens).
  Don't paste its contents into chats, PRs, or logs.
- **`tofu apply` must run before Ansible** on a fresh checkout — without it
  there is no inventory file for the playbook to read.
- New host-level variables that Ansible needs should be added to the
  `local_file "inventory"` block so they flow through automatically, rather
  than being hardcoded in the playbook.
- **The playbook doesn't deploy the app.** It only sets up the host (packages,
  Docker, ECR pull credentials, the Cloudflare tunnel). The app container,
  its state directories and SQLite file, migrations and seeding are owned by
  the separate `iac/app/` root module (kreuzwerker/docker provider, one
  OpenTofu workspace per environment), which the `deploy` job in
  `.github/workflows/ci.yml` applies. Change per-environment deploy settings
  (`RAILS_ENV`, ports, mounts, env vars) in `iac/app/main.tf`.
