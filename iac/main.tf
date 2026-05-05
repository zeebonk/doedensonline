terraform {
  backend "s3" {
    bucket  = "doedensonline-terraform"
    key     = "app"
    region  = "eu-west-1"
    profile = "doedensonline"
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
      version = "~> 4.0"
    }
  }
}

locals {
  region                  = "eu-west-1"
  availability_zone       = "eu-west-1a"
  domain                  = "doedensonline.nl"
  gijs_macbook_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhQZ/xpYhLpKddmIe0X3Cpi2YXXze/PqVYxMBn0+zmd7mVwI5Ki9eS9pA7AVsEpdKQDg4SV941xoVcJ9Jpe+ua0aKlSEJjBfgxH6V0zRSV5cN776uA3c37BAwaL9KzweHL0O4u79+JkAB+ergrDHpDz2WNpVKPgTJe0FzH7r4NT02zrbHMJVDX9gZlQwUNKLdJLpHrbuks2kjFzOuF3nMAqpPqgMM4EtZWhMgJ++2i4/m6Kub4F+mJxJpB2r3kYHO7vkaxWMp4Uhb/S8Y50KXVThkoZftFTXYex4zFRCuT8GiROZuzy9CirRdWA/TWWTz0n47KPzwYzkVKrzWfYLEJ gijs@gbox.local"
}

provider "aws" {
  region  = local.region
  profile = "doedensonline"
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

resource "aws_default_subnet" "doedensonline" {
  availability_zone = local.availability_zone
}

resource "aws_kms_key" "doedensonline" {
  description = "doedensonline"
}

resource "aws_kms_alias" "doedensonline" {
  name          = "alias/doedensonline"
  target_key_id = aws_kms_key.doedensonline.key_id
}

resource "aws_ecr_repository" "doedensonline" {
  name                 = "doedensonline"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.doedensonline.arn
  }
}

module "key_pair_gijs_macbook" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "gijs-macbook"
  public_key = local.gijs_macbook_public_key
}

resource "aws_ebs_volume" "persistent" {
  availability_zone = local.availability_zone
  type              = "gp3"
  size              = 1
  encrypted         = true
  kms_key_id        = aws_kms_key.doedensonline.arn
  tags = {
    Snapshot = "true"
  }
}

data "aws_iam_policy_document" "ecr_read_only_policy_document" {
  statement {
    sid = "AllowECRReadOnly"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = ["*"]
  }
}

module "ecr_read_only_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name = "ECRReadOnly"
  path = "/"

  policy = data.aws_iam_policy_document.ecr_read_only_policy_document.json
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
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name = "ECRPush"
  path = "/"

  policy = data.aws_iam_policy_document.ecr_push_policy_document.json
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

module "iam_role_github_actions" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role"

  name            = "github-actions"
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

resource "aws_iam_user" "doedensonline_dev" {
  name = "doedensonline-dev"
}

resource "aws_iam_user_policy_attachment" "doedensonline_dev_ecr_read_only" {
  user       = aws_iam_user.doedensonline_dev.name
  policy_arn = module.ecr_read_only_policy.arn
}

resource "aws_iam_access_key" "doedensonline_dev" {
  user = aws_iam_user.doedensonline_dev.name
}

moved {
  from = module.iam_assumable_role_webserver
  to   = module.iam_role_webserver
}

module "iam_role_webserver" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role"

  name = "webserver"

  trust_policy_permissions = {
    AllowAssumeRole = {
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["313336455033"]
        },
        {
          type        = "Service"
          identifiers = ["ec2.amazonaws.com"]
        }
      ]
    }
  }

  policies = {
    ECRReadOnly = module.ecr_read_only_policy.arn
  }
}

resource "aws_iam_instance_profile" "webserver" {
  name = "webserver"
  role = module.iam_role_webserver.name
}

module "ec2_instance_doedensonline" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.0"

  name                   = "doedensonline"
  ami                    = "ami-0fe0b2cf0e1f25c8a" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t3a.nano"
  subnet_id              = aws_default_subnet.doedensonline.id
  key_name               = "gijs-macbook"
  vpc_security_group_ids = [module.security_group_doedensonline_webserver.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.webserver.name

  ebs_optimized = true
  root_block_device = {
    volume_type = "gp3"
    volume_size = 10
    encrypted   = true
    kms_key_id  = aws_kms_key.doedensonline.arn
  }

  tags = {
    Snapshot = "true"
  }
  volume_tags = {
    Snapshot = "true"
  }
}

resource "aws_volume_attachment" "persistent" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.persistent.id
  instance_id = module.ec2_instance_doedensonline.id
}

module "security_group_doedensonline_webserver" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "doedensonline-webserver"
  vpc_id = aws_default_subnet.doedensonline.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "ssh-tcp", "all-icmp"]

  egress_rules = ["all-all"]
}

resource "aws_eip" "doedensonline" {
  instance = module.ec2_instance_doedensonline.id
}

resource "local_file" "inventory" {
  content = yamlencode({
    "prod" : {
      "vars" : {
        "rails_env" : "production",
        "domain" : "doedensonline.nl",
        "extra_domains" : ["www.doedensonline.nl"],
        "app_state_path" : "/app-state",
        "app_state_device" : "/dev/sdf",
      },
      "hosts" : {
        "prod-webserver" : {
          "ansible_host" : aws_eip.doedensonline.public_ip,
          "ansible_user" : "ec2-user",
          "smtp_host" : "email-smtp.${local.region}.amazonaws.com",
          "smtp_username" : module.iam_user_doedensonline_ses.access_key_id,
          "smtp_password" : module.iam_user_doedensonline_ses.access_key_ses_smtp_password_v4,
        },
      }
    },
    "dev" : {
      "vars" : {
        "rails_env" : "development",
        "domain" : "dev.doedensonline.nl",
        "extra_domains" : [],
        "app_state_path" : "/app-state/dev",
      },
      "hosts" : {
        "dev-webserver" : {
          "ansible_host" : hcloud_server.doedensonline.ipv4_address,
          "ansible_user" : "root",
          "smtp_host" : "email-smtp.${local.region}.amazonaws.com",
          "smtp_username" : module.iam_user_doedensonline_ses.access_key_id,
          "smtp_password" : module.iam_user_doedensonline_ses.access_key_ses_smtp_password_v4,
          "ecr_access_key_id" : aws_iam_access_key.doedensonline_dev.id,
          "ecr_secret_access_key" : aws_iam_access_key.doedensonline_dev.secret,
          "cloudflared_tunnel_token" : cloudflare_zero_trust_tunnel_cloudflared.dev.tunnel_token,
        },
      }
    },
  })
  filename = "${path.module}/inventory.yaml"
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

resource "tls_private_key" "github_actions_prod" {
  algorithm = "ED25519"
}

module "key_pair_github_actions_prod" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "github-actions"
  public_key = trimspace(tls_private_key.github_actions_prod.public_key_openssh)
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

  # ssh_keys is only honored at server creation. Adding the github-actions
  # key after the fact requires appending it to authorized_keys directly.
  lifecycle {
    ignore_changes = [ssh_keys]
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

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
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
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

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
  account_id = var.cloudflare_account_id
  zone       = local.domain
}

resource "cloudflare_record" "doedensonline" {
  zone_id = cloudflare_zone.doedensonline.id
  name    = local.domain
  type    = "A"
  content = aws_eip.doedensonline.public_ip
  ttl     = 60
  proxied = false
}

resource "cloudflare_record" "doedensonline_dev" {
  zone_id = cloudflare_zone.doedensonline.id
  name    = "dev.${local.domain}"
  type    = "A"
  content = hcloud_server.doedensonline.ipv4_address
  ttl     = 60
  proxied = false
}

resource "cloudflare_record" "doedensonline_dkim_record" {
  for_each = toset(aws_ses_domain_dkim.doedensonline.dkim_tokens)
  zone_id  = cloudflare_zone.doedensonline.id
  name     = "${each.key}._domainkey"
  type     = "CNAME"
  content  = "${each.key}.dkim.amazonses.com"
  ttl      = 60
  proxied  = false
}

resource "cloudflare_record" "doedensonline_amazonses_verification_record" {
  zone_id = cloudflare_zone.doedensonline.id
  name    = "_amazonses.${local.domain}"
  type    = "TXT"
  content = aws_ses_domain_identity.doedensonline.verification_token
  ttl     = 60
  proxied = false
}

# 32 random bytes, base64-encoded — what `cloudflared` expects for a tunnel secret.
resource "random_id" "dev_tunnel_secret" {
  byte_length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "dev" {
  account_id = var.cloudflare_account_id
  name       = "doedensonline-dev"
  secret     = random_id.dev_tunnel_secret.b64_std
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "dev" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.dev.id

  config {
    ingress_rule {
      hostname = "dev.${local.domain}"
      service  = "http://localhost:8080"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Backup
#
data "aws_iam_policy_document" "dlm_lifecycle" {
  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
}

module "iam_policy_dlm_lifecycle" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name = "DLMLifecycle"
  path = "/"

  policy = data.aws_iam_policy_document.dlm_lifecycle.json
}

moved {
  from = module.iam_assumable_role_dlm_lifecycle
  to   = module.iam_role_dlm_lifecycle
}

module "iam_role_dlm_lifecycle" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role"

  name = "dlm-lifecycle"

  trust_policy_permissions = {
    AllowAssumeRole = {
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "Service"
          identifiers = ["dlm.amazonaws.com"]
        }
      ]
    }
  }

  policies = {
    DLMLifecycle = module.iam_policy_dlm_lifecycle.arn
  }
}

resource "aws_dlm_lifecycle_policy" "doedensonline" {
  description        = "Doedensonline"
  execution_role_arn = module.iam_role_dlm_lifecycle.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "3 months of daily snapshots"

      create_rule {
        interval      = "24"
        interval_unit = "HOURS"
      }

      retain_rule {
        interval      = "3"
        interval_unit = "MONTHS"
      }

      copy_tags = false
    }

    target_tags = {
      Snapshot = "true"
    }
  }
}

# GitHub Actions secrets for the dev deploy job

locals {
  github_actions_dev_secrets = {
    DEV_SSH_HOST        = hcloud_server.doedensonline.ipv4_address
    DEV_SSH_PRIVATE_KEY = tls_private_key.github_actions_dev.private_key_openssh
    DEV_SMTP_HOST       = "email-smtp.${local.region}.amazonaws.com"
    DEV_SMTP_USERNAME   = module.iam_user_doedensonline_ses.access_key_id
    DEV_SMTP_PASSWORD   = module.iam_user_doedensonline_ses.access_key_ses_smtp_password_v4
    DEV_SECRET_KEY_BASE = random_id.dev_secret_key_base.hex
  }

  github_actions_prod_secrets = {
    PROD_SSH_HOST        = aws_eip.doedensonline.public_ip
    PROD_SSH_PRIVATE_KEY = tls_private_key.github_actions_prod.private_key_openssh
    PROD_SMTP_HOST       = "email-smtp.${local.region}.amazonaws.com"
    PROD_SMTP_USERNAME   = module.iam_user_doedensonline_ses.access_key_id
    PROD_SMTP_PASSWORD   = module.iam_user_doedensonline_ses.access_key_ses_smtp_password_v4
    PROD_SECRET_KEY_BASE = random_id.prod_secret_key_base.hex
  }
}

# Rails 4.0 secret_key_base for the production and development
# environments. 64 random bytes → 128 hex chars, the same length the
# Rails generator produces.
resource "random_id" "prod_secret_key_base" {
  byte_length = 64
}

resource "random_id" "dev_secret_key_base" {
  byte_length = 64
}

resource "github_actions_secret" "dev_deploy" {
  for_each    = local.github_actions_dev_secrets
  repository  = "doedensonline"
  secret_name = each.key
  value       = each.value
}

resource "github_actions_secret" "prod_deploy" {
  for_each    = local.github_actions_prod_secrets
  repository  = "doedensonline"
  secret_name = each.key
  value       = each.value
}


# Outputs

output "prod_ip" {
  description = "Prod server public IPv4"
  value       = aws_eip.doedensonline.public_ip
}

output "dev_ip" {
  description = "Dev server public IPv4"
  value       = hcloud_server.doedensonline.ipv4_address
}
