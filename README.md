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

- Adopt Rails 3.1 `has_secure_password` in the `User` model to replace the hand-rolled password hashing with bcrypt.
- Enable the Rails 3.1 asset pipeline: move `public/stylesheets/*` and `public/javascripts/*` (incl. TinyMCE vendor tree) into `app/assets/` and drop `config.assets.enabled = false`.
- Setup automated formatting.
- Standardize form label and error handling across views.
- See if the page title can be set from the view template.
