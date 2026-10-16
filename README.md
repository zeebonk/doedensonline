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

Also set `cloudflare_account_id` and `cloudflare_api_token`. Create the token
as an account-owned token (Manage Account → Account API Tokens) with these
permissions:

- On the entire account: Cloudflare Tunnel Write and Account API Tokens Write,
  so it can create the `doedensonline-deploy` token for the deploy job.
- On all zones in the account: Zone Write, Zone Settings Write, DNS Write and
  Dynamic URL Redirects Write.

CI reads these from the `HCLOUD_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` and
`CLOUDFLARE_API_TOKEN` secrets of the `server` environment.

Export a GitHub personal access token so Terraform can manage the `dev` and
`prod` environments and their secrets, used by the deploy job: a classic token
with `repo` scope, or a fine-grained one with read and write access to
Administration and Environments:

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
along with any drift. Both wait for an approval on the `server` environment.
To retry a failed apply, re-run the Server workflow run on `master`.

On first boot, cloud-init installs Docker on the server. The server's
cloud-init config only applies when the server is created; changing it
doesn't touch the existing server.

Nothing runs on a fresh server yet: each environment's Cloudflare tunnel,
DNS record, and app and tunnel containers come up with its first deploy (see
below).


## Push latest image to ECR

```
docker buildx build --push \
    -t 313336455033.dkr.ecr.eu-west-1.amazonaws.com/doedensonline:TAG \
    --platform=linux/amd64,linux/arm64 ./src
```

Tags are immutable, except the `cache-*` and `pr-*-cache-*` layer caches: a
push to an existing tag fails.

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
workspace per environment. It reaches Docker on the host over SSH as root, and
manages the environment's Cloudflare tunnel and DNS record. The variables and
`CLOUDFLARE_API_TOKEN` mirror the secrets of the `dev` and `prod` GitHub
environments, set by `iac/server/main.tf`. Any token with the same permissions
works, such as the one in `iac/server/terraform.tfvars`:

```
cd iac/app
export AWS_PROFILE=doedensonline
export CLOUDFLARE_API_TOKEN=...
tofu init
tofu workspace select dev
tofu apply -var image_tag=master.abc1234 -var ssh_host=... \
    -var smtp_host=... -var smtp_username=... -var smtp_password=...
```
