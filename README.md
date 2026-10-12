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


## Setup infrastructure

Copy the Terraform variables template and paste your Hetzner Cloud API token
(from the Hetzner Cloud console under Security → API Tokens, read-write scope):

```
cd iac/server
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
export AWS_PROFILE=doedensonline
tofu init
tofu apply
```

After that, CI takes over (`.github/workflows/server.yml`): every pull
request gets a plan in the job summary, and every push to `master` applies it,
along with any drift. To retry a failed apply or revert
drift, run the Server workflow manually on `master`.

On first boot, cloud-init installs Docker on the server. The server's
cloud-init config only applies when the server is created; changing it
doesn't touch the existing server.

Nothing runs on a fresh server yet: each environment's app and Cloudflare
tunnel containers come up with its first deploy (see below).


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
  applies `iac/app` in the `dev` workspace, which migrates and seeds the
  database and replaces the running container.
- **Prod** — publishing a GitHub Release builds and pushes an image tagged with
  the release tag, then applies `iac/app` in the `prod` workspace, which
  migrates the database and replaces the running prod container.

Both flows run the test, RuboCop, and OpenTofu format and
validate jobs first; a failure in any of those blocks the deploy.

### Roll back

Re-run the `deploy` job of the workflow run that deployed the version to
roll back to. A re-run reuses that run's image tag, so it redeploys that
image.

### Deploy manually

`iac/app` is a separate OpenTofu root module with its own state, one
workspace per environment. It reaches Docker on the host over SSH as root.
The variables mirror the `DEV_*`/`PROD_*` GitHub Actions secrets set by
`iac/server/main.tf`:

```
cd iac/app
export AWS_PROFILE=doedensonline
tofu init
tofu workspace select dev
tofu apply -var image_tag=master.abc1234 -var ssh_host=... \
    -var smtp_host=... -var smtp_username=... -var smtp_password=... \
    -var secret_key_base=... -var tunnel_token=...
```
