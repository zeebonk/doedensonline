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

Deploys target either `prod` (AWS EC2) or `dev` (Hetzner Cloud). Pass the target
group via `-e target=<group>`.

```
cd iac
pdm install
pdm run ansible-playbook -i inventory.yaml playbook.yaml -e target=prod
pdm run ansible-playbook -i inventory.yaml playbook.yaml -e target=dev
```

To dry-run and preview changes:

```
pdm run ansible-playbook -i inventory.yaml playbook.yaml --check --diff -e target=prod
```


## Provision the dev environment (one-off)

After `tofu apply` has created the Hetzner instance and the `dev.doedensonline.nl`
Route53 record, wait for DNS propagation (check with `dig dev.doedensonline.nl`)
and then issue the initial Let's Encrypt certificate on the dev box — the
Ansible cron only handles renewals:

```
ssh root@dev.doedensonline.nl \
    docker run --rm \
        -v /etc/letsencrypt:/etc/letsencrypt \
        -v /var/lib/letsencrypt:/var/lib/letsencrypt \
        -p 80:80 \
        certbot/certbot certonly \
        -d dev.doedensonline.nl \
        --standalone -n --agree-tos -m vandervoort.gijs@gmail.com
```

Then run the Ansible playbook with `-e target=dev` to configure the box and
start the app.
