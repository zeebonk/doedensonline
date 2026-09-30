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
  the release tag, then SSHes into the AWS EC2 prod host and replaces the
  running container.

Both flows run the test, RuboCop, ansible-lint, and `tofu fmt` jobs first; a
failure in any of those blocks the deploy.

### Manual deploy via Ansible

The Ansible playbook is still available for one-off runs (e.g. to re-converge
host config or roll back to a specific image). Pass the target group via
`-e target=<group>` and the image tag via `-e image_tag=<tag>`:

```
cd iac
uv sync
uv run ansible-playbook -i inventory.yaml playbook.yaml -e target=prod -e image_tag=1.0.5
uv run ansible-playbook -i inventory.yaml playbook.yaml -e target=dev -e image_tag=master.abc1234
```

To dry-run and preview changes:

```
uv run ansible-playbook -i inventory.yaml playbook.yaml --check --diff -e target=prod -e image_tag=1.0.5
```
