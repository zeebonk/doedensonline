terraform {
  # Credentials come from the environment: AWS_PROFILE=doedensonline
  # locally, the github-actions-server role in CI.
  backend "s3" {
    bucket       = "doedensonline-terraform"
    key          = "app"
    region       = "eu-west-1"
    use_lockfile = true
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.26"
    }
  }
}

locals {
  region                  = "eu-west-1"
  domain                  = "doedensonline.nl"
  gijs_macbook_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhQZ/xpYhLpKddmIe0X3Cpi2YXXze/PqVYxMBn0+zmd7mVwI5Ki9eS9pA7AVsEpdKQDg4SV941xoVcJ9Jpe+ua0aKlSEJjBfgxH6V0zRSV5cN776uA3c37BAwaL9KzweHL0O4u79+JkAB+ergrDHpDz2WNpVKPgTJe0FzH7r4NT02zrbHMJVDX9gZlQwUNKLdJLpHrbuks2kjFzOuF3nMAqpPqgMM4EtZWhMgJ++2i4/m6Kub4F+mJxJpB2r3kYHO7vkaxWMp4Uhb/S8Y50KXVThkoZftFTXYex4zFRCuT8GiROZuzy9CirRdWA/TWWTz0n47KPzwYzkVKrzWfYLEJ gijs@gbox.local"
}

provider "aws" {
  region = local.region
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "github" {
  owner = "zeebonk"
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_account_id" {
  type      = string
  sensitive = true
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "aws_kms_key" "doedensonline" {
  description = "doedensonline"
}

resource "aws_kms_alias" "doedensonline" {
  name          = "alias/doedensonline"
  target_key_id = aws_kms_key.doedensonline.key_id
}

# Only the layer caches get overwritten. Every other tag is pushed once, so
# no build can replace an image that a deploy (re-run) pulls by tag.
resource "aws_ecr_repository" "doedensonline" {
  name                 = "doedensonline"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"
  force_delete         = true
  image_tag_mutability_exclusion_filter {
    filter      = "cache-*"
    filter_type = "WILDCARD"
  }
  image_tag_mutability_exclusion_filter {
    filter      = "pr-*-cache-*"
    filter_type = "WILDCARD"
  }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.doedensonline.arn
  }
}

resource "aws_ecr_lifecycle_policy" "doedensonline" {
  repository = aws_ecr_repository.doedensonline.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain release tags (X.Y.Z) indefinitely"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*.*.*"]
          countType      = "imageCountMoreThan"
          countNumber    = 999999
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Retain the last 50 master.* images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["master.*"]
          countType      = "imageCountMoreThan"
          countNumber    = 50
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 3
        description  = "Retain the CI build cache (cache-*) indefinitely"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["cache-*"]
          countType      = "imageCountMoreThan"
          countNumber    = 999999
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 4
        description  = "Expire everything else after 7 days"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
    ]
  })
}

data "aws_iam_policy_document" "ecr_push_policy_document" {
  statement {
    sid = "AllowECRAuth"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
  statement {
    sid = "AllowECRPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [aws_ecr_repository.doedensonline.arn]
  }
}

module "ecr_push_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  name = "ECRPush"
  path = "/"

  policy = data.aws_iam_policy_document.ecr_push_policy_document.json
}

data "aws_iam_policy_document" "ecr_pull_policy_document" {
  statement {
    sid = "AllowECRAuth"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
  statement {
    sid = "AllowECRPull"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [aws_ecr_repository.doedensonline.arn]
  }
}

module "ecr_pull_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  name = "ECRPull"
  path = "/"

  policy = data.aws_iam_policy_document.ecr_pull_policy_document.json
}

# State of the ../app root module, one object per workspace.
data "aws_iam_policy_document" "deploy_state_policy_document" {
  statement {
    sid       = "AllowListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::doedensonline-terraform"]
  }
  statement {
    sid = "AllowDeployState"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::doedensonline-terraform/env:/*/deploy",
      "arn:aws:s3:::doedensonline-terraform/env:/*/deploy.tflock",
    ]
  }
}

module "deploy_state_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  name = "DeployState"
  path = "/"

  policy = data.aws_iam_policy_document.deploy_state_policy_document.json
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Builds and pushes images. PR builds push their layer cache too, so any
# job can assume it.
module "iam_role_github_actions_build" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.2"

  name            = "github-actions-build"
  use_name_prefix = false

  trust_policy_permissions = {
    AllowAssumeRoleFromGitHubActions = {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals = [
        {
          type        = "Federated"
          identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
        }
      ]
      condition = [
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values   = ["repo:zeebonk/doedensonline:*"]
        }
      ]
    }
  }

  policies = {
    ECRPush = module.ecr_push_policy.arn
  }
}

# Applies ../app. Only jobs in the `dev` and `prod` GitHub environments,
# which only master and release tags can deploy to, can assume it.
module "iam_role_github_actions_deploy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.2"

  name            = "github-actions-deploy"
  use_name_prefix = false

  trust_policy_permissions = {
    AllowAssumeRoleFromGitHubActionsDeployEnvironments = {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals = [
        {
          type        = "Federated"
          identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
        }
      ]
      condition = [
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:sub"
          values = [
            for environment in keys(local.github_deploy_environments) :
            "repo:zeebonk/doedensonline:environment:${environment}"
          ]
        }
      ]
    }
  }

  policies = {
    ECRPull     = module.ecr_pull_policy.arn
    DeployState = module.deploy_state_policy.arn
  }
}

# Plans this module on pull requests and applies it on master from CI. Only
# jobs in the `server` GitHub environment, which requires an approval, can
# assume it, not any job like github-actions-build. This module manages IAM,
# KMS and the OIDC provider, so it's admin-equivalent anyway.
module "iam_role_github_actions_server" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.2"

  name            = "github-actions-server"
  use_name_prefix = false

  trust_policy_permissions = {
    AllowAssumeRoleFromGitHubActionsServerEnvironment = {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals = [
        {
          type        = "Federated"
          identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
        }
      ]
      condition = [
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:sub"
          values   = ["repo:zeebonk/doedensonline:environment:server"]
        }
      ]
    }
  }

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}


# Hetzner

resource "hcloud_ssh_key" "gijs_macbook" {
  name       = "gijs-macbook"
  public_key = local.gijs_macbook_public_key
}

resource "tls_private_key" "github_actions_dev" {
  algorithm = "ED25519"
}

resource "hcloud_ssh_key" "github_actions" {
  name       = "github-actions"
  public_key = trimspace(tls_private_key.github_actions_dev.public_key_openssh)
}

resource "hcloud_server" "doedensonline" {
  name        = "doedensonline"
  server_type = "cx23"
  image       = "ubuntu-24.04"
  location    = "fsn1"
  backups     = true
  ssh_keys = [
    hcloud_ssh_key.gijs_macbook.id,
    hcloud_ssh_key.github_actions.id,
  ]

  user_data = <<-EOT
    #cloud-config
    packages:
      - docker.io
      - htop
      - vim
  EOT

  # ssh_keys and user_data are only honored at server creation, and changing
  # either would replace the server and its app state. Adding the
  # github-actions key after the fact requires appending it to
  # authorized_keys directly; user_data changes have to be applied by hand.
  lifecycle {
    ignore_changes = [ssh_keys, user_data]
  }
}

resource "hcloud_firewall" "doedensonline" {
  name = "doedensonline"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0"]
  }
}

resource "hcloud_firewall_attachment" "doedensonline" {
  firewall_id = hcloud_firewall.doedensonline.id
  server_ids  = [hcloud_server.doedensonline.id]
}


# AWS SES

resource "aws_ses_domain_identity" "doedensonline" {
  domain = local.domain
}

module "iam_user_doedensonline_ses" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "6.8.2"

  name                    = "doedensonline-ses"
  create_login_profile    = false
  password_reset_required = false
}

resource "aws_iam_user_policy" "allow_ses_sending" {
  name = "AmazonSesSendingAccess"
  user = module.iam_user_doedensonline_ses.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ses:SendRawEmail",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_ses_domain_dkim" "doedensonline" {
  domain = aws_ses_domain_identity.doedensonline.domain
}

# Cloudflare

resource "cloudflare_zone" "doedensonline" {
  account = {
    id = var.cloudflare_account_id
  }
  name = local.domain
}

resource "cloudflare_zone_setting" "doedensonline_always_use_https" {
  zone_id    = cloudflare_zone.doedensonline.id
  setting_id = "always_use_https"
  value      = "on"
}

# www.doedensonline.nl exists only so Cloudflare's edge can intercept
# requests and apply the redirect ruleset below — the tunnel never sees
# this hostname.
resource "cloudflare_dns_record" "doedensonline_www" {
  zone_id = cloudflare_zone.doedensonline.id
  name    = "www.${local.domain}"
  type    = "CNAME"
  content = local.domain
  ttl     = 1
  proxied = true
}

resource "cloudflare_dns_record" "doedensonline_dkim_record" {
  for_each = toset(aws_ses_domain_dkim.doedensonline.dkim_tokens)
  zone_id  = cloudflare_zone.doedensonline.id
  name     = "${each.key}._domainkey.${local.domain}"
  type     = "CNAME"
  content  = "${each.key}.dkim.amazonses.com"
  ttl      = 60
  proxied  = false
}

resource "cloudflare_dns_record" "doedensonline_amazonses_verification_record" {
  zone_id = cloudflare_zone.doedensonline.id
  name    = "_amazonses.${local.domain}"
  type    = "TXT"
  content = aws_ses_domain_identity.doedensonline.verification_token
  ttl     = 60
  proxied = false
}

# Each environment's tunnel, ingress config and DNS record moved to ../app,
# which imported them. Forget them here without destroying them, along with
# the tunnel secrets, which remotely-managed tunnels don't need.

removed {
  from = cloudflare_dns_record.doedensonline

  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_dns_record.doedensonline_dev

  lifecycle {
    destroy = false
  }
}

removed {
  from = random_bytes.dev_tunnel_secret

  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_tunnel_cloudflared.dev

  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_tunnel_cloudflared_config.dev

  lifecycle {
    destroy = false
  }
}

removed {
  from = random_bytes.prod_tunnel_secret

  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_tunnel_cloudflared.prod

  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_tunnel_cloudflared_config.prod

  lifecycle {
    destroy = false
  }
}

# Strip a leading `www.` from any hostname in the zone and redirect to
# the bare hostname. Handled at the Cloudflare edge — the tunnel never
# sees `www.*` traffic.
resource "cloudflare_ruleset" "redirect_www_to_apex" {
  zone_id = cloudflare_zone.doedensonline.id
  name    = "Redirect www.* to apex"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules = [
    {
      action      = "redirect"
      expression  = "starts_with(http.host, \"www.\")"
      description = "Redirect www.* to apex"
      enabled     = true

      action_parameters = {
        from_value = {
          status_code = 301
          target_url = {
            expression = "concat(\"https://\", wildcard_replace(http.host, \"www.*\", \"$${1}\"), http.request.uri.path)"
          }
          preserve_query_string = true
        }
      }
    },
  ]
}

# Lets the deploy job (../app) manage each environment's tunnel and DNS
# record. Tunnel permissions only scope to the whole account, and both
# hostnames are in one zone, so dev and prod share the token.
locals {
  # Permission group name => scope.
  deploy_token_permission_groups = {
    "Cloudflare Tunnel Write" = "com.cloudflare.api.account"
    "DNS Write"               = "com.cloudflare.api.account.zone"
    "Zone Read"               = "com.cloudflare.api.account.zone"
  }
}

data "cloudflare_account_api_token_permission_groups_list" "deploy" {
  for_each   = local.deploy_token_permission_groups
  account_id = var.cloudflare_account_id
  name       = each.key
  scope      = each.value
}

resource "cloudflare_account_token" "deploy" {
  account_id = var.cloudflare_account_id
  name       = "doedensonline-deploy"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        { id = data.cloudflare_account_api_token_permission_groups_list.deploy["Cloudflare Tunnel Write"].result[0].id },
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.${var.cloudflare_account_id}" = "*"
      })
    },
    {
      effect = "allow"
      permission_groups = [
        { id = data.cloudflare_account_api_token_permission_groups_list.deploy["DNS Write"].result[0].id },
        { id = data.cloudflare_account_api_token_permission_groups_list.deploy["Zone Read"].result[0].id },
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.${var.cloudflare_account_id}" = {
          "com.cloudflare.api.account.zone.${cloudflare_zone.doedensonline.id}" = "*"
        }
      })
    },
  ]
}

# GitHub environments and secrets for the deploy job

locals {
  # Which refs can deploy to each environment.
  github_deploy_environments = {
    dev  = { branch_pattern = "master" }
    prod = { tag_pattern = "*.*.*" }
  }

  github_deploy_secrets = {
    dev = {
      SSH_HOST             = hcloud_server.doedensonline.ipv4_address
      SSH_PRIVATE_KEY      = tls_private_key.github_actions_dev.private_key_openssh
      SMTP_HOST            = "email-smtp.${local.region}.amazonaws.com"
      SMTP_USERNAME        = module.iam_user_doedensonline_ses.access_key_id
      SMTP_PASSWORD        = module.iam_user_doedensonline_ses.access_key_ses_smtp_password_v4
      CLOUDFLARE_API_TOKEN = cloudflare_account_token.deploy.value
    }
    prod = {
      SSH_HOST             = hcloud_server.doedensonline.ipv4_address
      SSH_PRIVATE_KEY      = tls_private_key.github_actions_dev.private_key_openssh
      SMTP_HOST            = "email-smtp.${local.region}.amazonaws.com"
      SMTP_USERNAME        = module.iam_user_doedensonline_ses.access_key_id
      SMTP_PASSWORD        = module.iam_user_doedensonline_ses.access_key_ses_smtp_password_v4
      CLOUDFLARE_API_TOKEN = cloudflare_account_token.deploy.value
    }
  }
}

resource "github_repository_environment" "deploy" {
  for_each    = local.github_deploy_environments
  repository  = "doedensonline"
  environment = each.key

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "deploy" {
  for_each       = local.github_deploy_environments
  repository     = "doedensonline"
  environment    = github_repository_environment.deploy[each.key].environment
  branch_pattern = lookup(each.value, "branch_pattern", null)
  tag_pattern    = lookup(each.value, "tag_pattern", null)
}

resource "github_actions_environment_secret" "deploy" {
  for_each = merge([
    for environment, secrets in local.github_deploy_secrets : {
      for name, value in secrets : "${environment}/${name}" => {
        environment = environment
        name        = name
        value       = value
      }
    }
  ]...)
  repository  = "doedensonline"
  environment = github_repository_environment.deploy[each.value.environment].environment
  secret_name = each.value.name
  value       = each.value.value
}


# Outputs

output "dev_ip" {
  description = "Dev server public IPv4"
  value       = hcloud_server.doedensonline.ipv4_address
}
