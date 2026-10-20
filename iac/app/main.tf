# Deploy the app container, its Cloudflare tunnel and DNS record

locals {
  environments = {
    dev = {
      rails_env = "development"
      hostname  = "dev.doedensonline.nl"
      port      = 8080
      seed      = true
    }
    prod = {
      rails_env = "production"
      hostname  = "doedensonline.nl"
      port      = 8081
      seed      = false
    }
  }

  env = local.environments[terraform.workspace]

  name       = "doedensonline-${terraform.workspace}"
  state_path = "/app-state/${terraform.workspace}"

  # Hetzner backups run in the UTC window reported by iac/server. Take the
  # database dump two hours before the window begins so each server backup
  # contains a recent, restorable dump.
  postgres_backup_hour = (tonumber(split("-", var.hetzner_backup_window)[0]) + 22) % 24

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
    "SECRET_KEY_BASE=${random_bytes.secret_key_base.hex}",
  ]

  log_opts = {
    max-size = "10m"
    max-file = "5"
  }
}

# Rails secret_key_base
resource "random_bytes" "secret_key_base" {
  length = 64
}

# Kept in the per-environment app state, so dev and prod never share a
# database credential.
resource "random_password" "postgres" {
  length  = 32
  special = false
}

# The app, database and backup sidecar communicate only over this private
# per-environment network. PostgreSQL deliberately has no published port.
resource "docker_network" "this" {
  name = local.name
}

# Pin the PostgreSQL major version, while pulling patched 18.x images during
# deploys when the registry digest changes.
data "docker_registry_image" "postgres" {
  name = "postgres:18-alpine"
}

resource "docker_image" "postgres" {
  name          = data.docker_registry_image.postgres.name
  keep_locally  = true
  pull_triggers = [data.docker_registry_image.postgres.sha256_digest]
}

resource "docker_container" "postgres" {
  name                  = "${local.name}-postgresql"
  image                 = docker_image.postgres.image_id
  restart               = "always"
  destroy_grace_seconds = 60
  env = [
    "POSTGRES_USER=doedensonline",
    "POSTGRES_PASSWORD=${random_password.postgres.result}",
    "POSTGRES_DB=doedensonline",
  ]

  log_driver = "json-file"
  log_opts   = local.log_opts

  healthcheck {
    test     = ["CMD-SHELL", "pg_isready -U doedensonline -d doedensonline"]
    interval = "10s"
    timeout  = "5s"
    retries  = 6
  }

  wait         = true
  wait_timeout = 60

  networks_advanced {
    name = docker_network.this.name
  }

  # PostgreSQL 18 changed its default volume location from
  # /var/lib/postgresql/data to /var/lib/postgresql.
  volumes {
    host_path      = "${local.state_path}/postgresql"
    container_path = "/var/lib/postgresql"
  }
}

# A version-matched pg_dump runs nightly before the Hetzner backup window.
# A failed dump is never retained or allowed to prune older backups.
resource "docker_container" "postgres_backup" {
  name       = "${local.name}-postgresql-backup"
  image      = docker_image.postgres.image_id
  restart    = "always"
  command    = ["crond", "-f"]
  depends_on = [docker_container.postgres]
  env = [
    "PGHOST=${docker_container.postgres.name}",
    "PGUSER=doedensonline",
    "PGPASSWORD=${random_password.postgres.result}",
    "PGDATABASE=doedensonline",
  ]

  log_driver = "json-file"
  log_opts   = local.log_opts

  networks_advanced {
    name = docker_network.this.name
  }

  volumes {
    host_path      = "${local.state_path}/postgresql-backups"
    container_path = "/backups"
  }

  upload {
    file        = "/usr/local/bin/backup-postgresql"
    executable  = true
    permissions = "0755"
    content     = <<-EOT
      #!/bin/sh
      set -eu

      backup_dir=/backups
      dump_name="$(date +%F).dump"
      temporary_dump="$${backup_dir}/.$${dump_name}.$$"

      trap 'rm -f "$${temporary_dump}"' EXIT
      pg_dump -Fc --file="$${temporary_dump}"
      mv "$${temporary_dump}" "$${backup_dir}/$${dump_name}"
      trap - EXIT

      ls -1t "$${backup_dir}"/*.dump 2>/dev/null | tail -n +4 | xargs -r rm --
    EOT
  }

  upload {
    file    = "/etc/crontabs/root"
    content = "0 ${local.postgres_backup_hour} * * * /usr/local/bin/backup-postgresql\\n"
  }
}

resource "docker_image" "app" {
  name         = "${var.registry}/doedensonline:${var.image_tag}"
  keep_locally = true

  # Pull the new image before the old container is removed.
  lifecycle {
    create_before_destroy = true
  }
}

# One-shot container that migrates (and on dev, seeds) the database
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

resource "docker_image" "cloudflared" {
  name = "cloudflare/cloudflared:2026.10.0"

  # Dev and prod each manage this image on the same host. Removing it when
  # a tag bump reaches dev would fail while prod's tunnel still uses it.
  keep_locally = true
}

resource "docker_container" "cloudflared" {
  name         = "${local.name}-tunnel"
  image        = docker_image.cloudflared.image_id
  restart      = "always"
  network_mode = "host"
  command      = ["tunnel", "--no-autoupdate", "run"]
  env          = ["TUNNEL_TOKEN=${data.cloudflare_zero_trust_tunnel_cloudflared_token.this.token}"]

  log_driver = "json-file"
  log_opts   = local.log_opts
}

data "cloudflare_zone" "this" {
  filter = {
    name = "doedensonline.nl"
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id = data.cloudflare_zone.this.account.id
  name       = local.name
  config_src = "cloudflare" # managed via API, not file
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  account_id = data.cloudflare_zone.this.account.id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  account_id = data.cloudflare_zone.this.account.id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
  source     = "cloudflare"

  config = {
    ingress = [
      {
        hostname = local.env.hostname
        service  = "http://localhost:${local.env.port}"
      },
      {
        service = "http_status:404"
      },
    ]
  }
}

resource "cloudflare_dns_record" "this" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = local.env.hostname
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  # Cloudflare ignores TTL for proxied records but still requires a value;
  # `1` means "auto" in their API.
  ttl     = 1
  proxied = true
}
