# Working on the Ruby application

The Rails app lives in `src/` and is developed and run exclusively through
Docker Compose. Ruby, Bundler, and gems are not installed on the host — every
Ruby/Rails command must run inside the `app` service container.

Always `cd src` first, then use one of the patterns below.

## Run the app

```
docker compose up
```

## Run the test suite

```
docker compose run --rm -e RAILS_ENV=test app rake test
```

## Run RuboCop

```
docker compose run --rm app bundle exec rubocop
docker compose run --rm app bundle exec rubocop --auto-correct
```

## Install or update gems

After editing `Gemfile`, rebuild the image so `bundle install` runs against the
new dependencies (gems are baked into the image, not stored on a host volume):

```
docker compose build app
```

For ad-hoc bundler commands:

```
docker compose run --rm app bundle <command>
```

## Run database migrations / rake tasks

```
docker compose run --rm app rake db:migrate
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
- Don't add gems to a local `Gemfile.lock` outside the container; let
  `docker compose build app` regenerate it.


# Infrastructure: Terraform → Ansible handoff

Terraform (`iac/main.tf`) provisions the cloud resources (Hetzner VMs,
Cloudflare tunnels, AWS SES/IAM, GitHub Actions secrets) **and** writes a
local `iac/inventory.yaml` via a `local_file` resource. This generated file is
the bridge between Terraform and Ansible:

- Terraform owns infra-level facts: server IPs, tunnel tokens, SES SMTP
  credentials, ECR access keys, per-instance vars (`rails_env`,
  `app_state_path`, `host_ports`, etc.).
- It serializes those facts into `iac/inventory.yaml` as a standard Ansible
  inventory with `prod` and `dev` groups.
- Ansible (`playbook.yaml`, `sync.yaml`) then consumes that inventory to
  provision/converge the same VMs:

  ```
  cd iac
  uv run ansible-playbook -i inventory.yaml playbook.yaml -e target=prod -e image_tag=...
  ```

Implications:

- **`iac/inventory.yaml` is generated, not authored.** It is gitignored. Don't
  edit it by hand and don't commit it — changes will be overwritten on the
  next `tofu apply`. To change inventory contents, edit the `local_file
  "inventory"` block in `main.tf`.
- **It contains secrets** (SMTP password, ECR keys, Cloudflare tunnel tokens).
  Don't paste its contents into chats, PRs, or logs.
- **`tofu apply` must run before Ansible** on a fresh checkout — without it
  there is no inventory file for the playbook to read.
- New host-level variables that Ansible needs should be added to the
  `local_file "inventory"` block so they flow through automatically, rather
  than being hardcoded in the playbook.
