# Setup


## Run locally

```
cd src
docker compose up
```

The application will be available at http://127.0.0.1:8080.


## Setup AWS infrastructure

```
cd iac
tofu apply
```


## Push latest image to ECR

```
cd src
docker compose build app
docker compose push app
```

To push with a custom tag:

```
TAG=mytag docker compose build app
TAG=mytag docker compose push app
```


## Deploy application

```
cd iac
pdm install
pdm run ansible-playbook -i inventory.yaml playbook.yaml
pdm run ansible-playbook -i inventory.yaml sync.yaml
```

To dry-run and preview changes:

```
pdm run ansible-playbook -i inventory.yaml playbook.yaml --check --diff
```
