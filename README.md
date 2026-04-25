# Setup


## Run locally

```
cd src
docker compose up
```

The application will be available at http://127.0.0.1:8080.


## Run tests

```
cd src
docker compose run --rm -e RAILS_ENV=test app rake test
```


## Run RuboCop

```
cd src
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
uv run ansible-lint playbook.yaml sync.yaml
uv run ansible-playbook --syntax-check -i localhost, -e target=localhost playbook.yaml
uv run ansible-playbook --syntax-check -i localhost, -e target=localhost sync.yaml
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
cd src
docker buildx build --push \
    -t 313336455033.dkr.ecr.eu-west-1.amazonaws.com/doedensonline:TAG \
    --platform=linux/amd64 .
```


## Deploy application

Deploys target either `prod` (AWS EC2) or `dev` (Hetzner Cloud). Pass the target
group via `-e target=<group>`.

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
