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
      "hosts" : {
        "main" : {
          "ansible_host" : aws_eip.doedensonline.public_ip,
          "ansible_user" : "ec2-user",
          "smtp_host" : "email-smtp.${local.region}.amazonaws.com",
          "smtp_username" : module.iam_user_doedensonline_ses.access_key_id,
          "smtp_password" : module.iam_user_doedensonline_ses.access_key_ses_smtp_password_v4,
        },
      }
    },
    "dev" : {
      "hosts" : {
        "main" : {
          "ansible_host" : hcloud_server.doedensonline.ipv4_address,
          "ansible_user" : "root",
          "smtp_host" : "email-smtp.${local.region}.amazonaws.com",
          "smtp_username" : module.iam_user_doedensonline_ses.access_key_id,
          "smtp_password" : module.iam_user_doedensonline_ses.access_key_ses_smtp_password_v4,
          "ecr_access_key_id" : aws_iam_access_key.doedensonline_dev.id,
          "ecr_secret_access_key" : aws_iam_access_key.doedensonline_dev.secret,
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

resource "hcloud_server" "doedensonline" {
  name        = "doedensonline"
  server_type = "cx23"
  image       = "ubuntu-24.04"
  location    = "fsn1"
  backups     = true
  ssh_keys    = [hcloud_ssh_key.gijs_macbook.id]
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

resource "aws_route53_record" "doedensonline_dkim_record" {
  for_each = toset(aws_ses_domain_dkim.doedensonline.dkim_tokens)
  zone_id  = aws_route53_zone.doedensonline.zone_id
  name     = "${each.key}._domainkey"
  type     = "CNAME"
  ttl      = "60"
  records  = ["${each.key}.dkim.amazonses.com"]
}

resource "aws_route53_record" "doedensonline_amazonses_verification_record" {
  zone_id = aws_route53_zone.doedensonline.zone_id
  name    = "_amazonses.${local.domain}"
  type    = "TXT"
  ttl     = "60"
  records = [aws_ses_domain_identity.doedensonline.verification_token]
}


# Route53

resource "aws_route53_zone" "doedensonline" {
  name = local.domain
}

resource "aws_route53_record" "doedensonline" {
  zone_id = aws_route53_zone.doedensonline.zone_id
  name    = local.domain
  type    = "A"
  ttl     = 60
  records = [aws_eip.doedensonline.public_ip]
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

# Outputs

output "prod_ip" {
  description = "Prod server public IPv4"
  value       = aws_eip.doedensonline.public_ip
}

output "dev_ip" {
  description = "Dev server public IPv4"
  value       = hcloud_server.doedensonline.ipv4_address
}
