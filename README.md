# Setup

## Create S3 Terraform state S3 bucket manually

...

## Setup AWS infrastructure

```
terraform apply
```


## Push latest image to ECR

```
cd src
docker compose build app
docker compuse push app
```

## Deploy application

```
poetry run ansible-playbook -i inventory.yaml playbook.yaml
poetry run ansible-playbook -i inventory.yaml sync.yaml
```
