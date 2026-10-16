provider "aws" {
  region = "eu-west-1"
}

data "aws_ecr_authorization_token" "this" {}

provider "docker" {
  host = "ssh://root@${var.ssh_host}"

  registry_auth {
    address  = var.registry
    username = data.aws_ecr_authorization_token.this.user_name
    password = data.aws_ecr_authorization_token.this.password
  }
}

provider "cloudflare" {}
