# Deploys the app container to a host provisioned by ../server/main.tf. Kept in its
# own root module and state so CI can deploy without touching (or having
# access to) the infrastructure state.
#
# One OpenTofu workspace per environment: `dev` or `prod`.

terraform {
  # Credentials come from the environment: AWS_PROFILE=doedensonline
  # locally, the github-actions role in CI.
  backend "s3" {
    bucket       = "doedensonline-terraform"
    key          = "deploy"
    region       = "eu-west-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }
  }
}

variable "ssh_host" {
  description = "Host to deploy to; Docker is reached over SSH as root."
  type        = string
}

variable "image_tag" {
  description = "Tag of the app image in ECR to deploy."
  type        = string
}

variable "smtp_host" {
  type = string
}

variable "smtp_username" {
  type = string
}

variable "smtp_password" {
  type      = string
  sensitive = true
}

variable "secret_key_base" {
  type      = string
  sensitive = true
}

locals {
  registry = "313336455033.dkr.ecr.eu-west-1.amazonaws.com"

  environments = {
    dev = {
      rails_env = "development"
      port      = 8080
      seed      = true
    }
    prod = {
      rails_env = "production"
      port      = 8081
      seed      = false
    }
  }

  # Fails with "Invalid index" outside the dev/prod workspaces.
  env = local.environments[terraform.workspace]

  name       = "doedensonline-${terraform.workspace}"
  state_path = "/app-state/${terraform.workspace}"

  # Host directory under state_path => container path.
  volumes = {
    db     = "/app/storage"
    small  = "/app/public/images/small"
    medium = "/app/public/images/medium"
    large  = "/app/public/images/large"
  }

  container_env = [
    "RAILS_ENV=${local.env.rails_env}",
    "DO_SMTP_HOST=${var.smtp_host}",
    "DO_SMTP_USERNAME=${var.smtp_username}",
    "DO_SMTP_PASSWORD=${var.smtp_password}",
    "SECRET_KEY_BASE=${var.secret_key_base}",
  ]

  # Docker doesn't rotate json-file logs by default.
  log_opts = {
    max-size = "10m"
    max-file = "5"
  }
}

provider "aws" {
  region = "eu-west-1"
}

# The Docker daemon doesn't use the host's ECR credential helper, so pass
# registry credentials along with the pull.
data "aws_ecr_authorization_token" "this" {}

provider "docker" {
  host = "ssh://root@${var.ssh_host}"

  registry_auth {
    address  = local.registry
    username = data.aws_ecr_authorization_token.this.user_name
    password = data.aws_ecr_authorization_token.this.password
  }
}

resource "docker_image" "app" {
  name         = "${local.registry}/doedensonline:${var.image_tag}"
  keep_locally = true

  # Pull the new image before the old container is removed.
  lifecycle {
    create_before_destroy = true
  }
}

# One-shot container that migrates (and on dev, seeds) the database before
# the app container starts. Its logs stay available through `docker logs`.
resource "docker_container" "migrate" {
  name     = "${local.name}-migrate"
  image    = docker_image.app.image_id
  command  = concat(["bundle", "exec", "rails", "db:migrate"], local.env.seed ? ["db:seed"] : [])
  env      = local.container_env
  attach   = true
  must_run = false

  log_driver = "json-file"
  log_opts   = local.log_opts

  volumes {
    host_path      = "${local.state_path}/db"
    container_path = local.volumes.db
  }

  lifecycle {
    postcondition {
      condition     = self.exit_code == 0
      error_message = "Database migration failed; see `docker logs ${self.name}` on the host."
    }
  }
}

resource "docker_container" "app" {
  name    = local.name
  image   = docker_image.app.image_id
  restart = "always"
  env     = local.container_env

  log_driver = "json-file"
  log_opts   = local.log_opts

  healthcheck {
    test           = ["CMD", "wget", "-q", "--spider", "http://127.0.0.1:8080/up"]
    interval       = "30s"
    timeout        = "5s"
    retries        = 3
    start_period   = "30s"
    start_interval = "1s"
  }

  wait         = true
  wait_timeout = 60

  ports {
    internal = 8080
    external = local.env.port
    ip       = "127.0.0.1"
  }

  dynamic "volumes" {
    for_each = local.volumes
    content {
      host_path      = "${local.state_path}/${volumes.key}"
      container_path = volumes.value
    }
  }

  depends_on = [docker_container.migrate]
}
