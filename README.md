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


## Setup AWS infrastructure

```
cd iac
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

```
cd iac
pdm install
pdm run ansible-playbook -i inventory.yaml playbook.yaml
```

To dry-run and preview changes:

```
pdm run ansible-playbook -i inventory.yaml playbook.yaml --check --diff
```


# TODO

- Fix `ApplicationController#validate_author`: its `return redirect_to` only exits the helper, so callers still mutate data and then double-render.
- Delete `src/app/controllers/application.rb`: it is a stale Rails-1.x-era duplicate of `ApplicationController` shadowed by `application_controller.rb`.
