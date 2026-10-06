# Setup


## Run locally

```
docker compose up
```

The application will be available at http://127.0.0.1:8080.


## Run tests

```
docker compose run --rm -e RAILS_ENV=test app bundle exec rails test
```


## Run RuboCop

```
docker compose run --rm app bundle exec rubocop
```

To auto-correct fixable offences:

```
docker compose run --rm app bundle exec rubocop --auto-correct
```


## Lint Ansible playbooks

```
cd iac
uv sync --all-groups
uv run ansible-lint playbook.yaml
uv run ansible-playbook --syntax-check -i localhost, -e target=localhost playbook.yaml
```


## Setup infrastructure

Copy the Terraform variables template and paste your Hetzner Cloud API token
(from the Hetzner Cloud console under Security → API Tokens, read-write scope):

```
cd iac
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set hcloud_token
```

Export a GitHub personal access token with `repo` scope so Terraform can
manage the GitHub Actions secrets used by the dev deploy workflow:

```
export GITHUB_TOKEN=...
```

Then apply:

```
tofu init
tofu apply
```


## Push latest image to ECR

```
docker buildx build --push \
    -t 313336455033.dkr.ecr.eu-west-1.amazonaws.com/doedensonline:TAG \
    --platform=linux/amd64,linux/arm64 ./src
```

Local development (`docker compose`) builds for the host's native
architecture. CI builds and tests the image natively on both amd64 and arm64
runners and only tags the combined multi-arch image once both succeed.


## Deploy application

Releases are automated via GitHub Actions:

- **Dev** — every push to `master` builds and pushes the image to ECR, then
  SSHes into the Hetzner dev host and replaces the running container.
- **Prod** — publishing a GitHub Release builds and pushes an image tagged with
  the release tag, then SSHes into the Hetzner host and replaces the running
  prod container.

Both flows run the test, RuboCop, ansible-lint, and `tofu fmt` jobs first; a
failure in any of those blocks the deploy.

### Roll back

Re-run the `deploy-prod` (or `deploy-dev`) job of the workflow run that
deployed the version to roll back to. A re-run reuses that run's image tag, so
it redeploys that image.

### Provision hosts via Ansible

The playbook converges the host-level config the deploy jobs rely on
(packages, Docker, ECR pull credentials, the Cloudflare tunnel); it doesn't
deploy the application. Run it after `tofu apply`, and on a fresh host before
its first deploy. Pass the target group via `-e target=<group>`:

```
cd iac
uv sync
uv run ansible-playbook -i inventory.yaml playbook.yaml -e target=prod
uv run ansible-playbook -i inventory.yaml playbook.yaml -e target=dev
```

To dry-run and preview changes:

```
uv run ansible-playbook -i inventory.yaml playbook.yaml --check --diff -e target=prod
```
