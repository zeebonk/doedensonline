# PostgreSQL, its private network and scheduled backups.

locals {
  # Hetzner backups run in the UTC window reported by iac/server. Take the
  # database dump two hours before the window begins so each server backup
  # contains a recent, restorable dump.
  postgres_backup_hour = (tonumber(split("-", var.hetzner_backup_window)[0]) + 22) % 24
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
