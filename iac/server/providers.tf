provider "aws" {
  region = local.region
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "github" {
  owner = "zeebonk"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
