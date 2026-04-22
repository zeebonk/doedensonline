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


## Setup infrastructure

Copy the Terraform variables template and paste your Hetzner Cloud API token
(from the Hetzner Cloud console under Security → API Tokens, read-write scope):

```
cd iac
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set hcloud_token
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

```
cd iac
pdm install
pdm run ansible-playbook -i inventory.yaml playbook.yaml
```

To dry-run and preview changes:

```
pdm run ansible-playbook -i inventory.yaml playbook.yaml --check --diff
```
