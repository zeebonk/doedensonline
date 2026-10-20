# Deploy the app container, its Cloudflare tunnel and DNS record.

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

# The app, database and backup sidecar communicate only over this private
# per-environment network. PostgreSQL deliberately has no published port.
resource "docker_network" "this" {
  name = local.name
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
