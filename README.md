# Setup


## Setup AWS infrastructure

```
cd iac
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
cd iac
pdm install
pdm run ansible-playbook -i inventory.yaml playbook.yaml
pdm run ansible-playbook -i inventory.yaml sync.yaml
```
