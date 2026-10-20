# DoedensOnline

DoedensOnline is the website of the Doedens family, at
[doedensonline.nl](https://doedensonline.nl). Family members sign in to
share news and photo albums and to comment on them. The site is in Dutch.

The site is a Rails app in `src/`. OpenTofu in `iac/` sets up the server and
deploys the app. GitHub Actions tests every change, deploys every push to
`master` to [dev.doedensonline.nl](https://dev.doedensonline.nl) and every
GitHub Release to production.


## Run locally

You need Docker and [mise](https://mise.jdx.dev). From the repo root:

```
mise trust
mise install
mise run app:serve
```

Open http://127.0.0.1:8080 and sign in as `Gijs` with the password
`password`.


## Everything else

Tests, linting, releases, deploys and the infrastructure all run as mise
tasks, locally and in CI. To list them:

```
mise tasks
```

`mise run <task> --help` shows the arguments of a task.

## Deploy manually

`iac/app` deploys the app alongside a private PostgreSQL container and its
nightly backups. To apply one environment manually, provide the same values as
the deploy workflow, including the Hetzner backup window:

```
mise run deployment:apply dev <image-tag> -var hetzner_backup_window=22-02
```
