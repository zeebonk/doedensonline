provider "heroku" {}

variable "ddo_secret_key" {}
variable "ddo_debug" {}
variable "ddo_allowed_hosts" {}
variable "ddo_static_url" {}
variable "ddo_static_root" {}

variable "django_superuser_username" {}
variable "django_superuser_password" {}
variable "django_superuser_email" {}

variable "nr_environment" {}
variable "nr_license_key" {}

resource "heroku_app" "doedensonline" {
  name   = "doedensonline"
  region = "eu"
  stack  = "container"

  config_vars = {
    DDO_DEBUG         = var.ddo_debug
    DDO_ALLOWED_HOSTS = var.ddo_allowed_hosts
    DDO_STATIC_URL    = var.ddo_static_url
    DDO_STATIC_ROOT   = var.ddo_static_root
  }

  sensitive_config_vars = {
    DDO_SECRET_KEY            = var.ddo_secret_key
    DJANGO_SUPERUSER_USERNAME = var.django_superuser_username
    DJANGO_SUPERUSER_PASSWORD = var.django_superuser_password
    DJANGO_SUPERUSER_EMAIL    = var.django_superuser_email
    NEW_RELIC_ENVIRONMENT     = var.nr_environment
    NEW_RELIC_LICENSE_KEY     = var.nr_license_key
  }
}

resource "heroku_build" "doedensonline" {
  app = heroku_app.doedensonline.id
  source = {
    path = "../src"
  }
}

resource "heroku_formation" "doedensonline" {
  app      = heroku_app.doedensonline.id
  type     = "web"
  quantity = 1
  size     = "free"
}

resource "heroku_addon" "doedensonline" {
  app  = heroku_app.doedensonline.name
  plan = "heroku-postgresql:hobby-dev"
}

