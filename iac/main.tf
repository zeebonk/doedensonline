terraform {
  backend "s3" {
    bucket  = "doedensonline-terraform"
    key     = "app"
    region  = "eu-west-1"
    profile = "doedensonline"
  }
}

locals {
  region            = "eu-west-1"
  availability_zone = "eu-west-1a"
  domain            = "doedensonline.nl"
}

provider "aws" {
  region  = local.region
  profile = "doedensonline"
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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhQZ/xpYhLpKddmIe0X3Cpi2YXXze/PqVYxMBn0+zmd7mVwI5Ki9eS9pA7AVsEpdKQDg4SV941xoVcJ9Jpe+ua0aKlSEJjBfgxH6V0zRSV5cN776uA3c37BAwaL9KzweHL0O4u79+JkAB+ergrDHpDz2WNpVKPgTJe0FzH7r4NT02zrbHMJVDX9gZlQwUNKLdJLpHrbuks2kjFzOuF3nMAqpPqgMM4EtZWhMgJ++2i4/m6Kub4F+mJxJpB2r3kYHO7vkaxWMp4Uhb/S8Y50KXVThkoZftFTXYex4zFRCuT8GiROZuzy9CirRdWA/TWWTz0n47KPzwYzkVKrzWfYLEJ gijs@gbox.local"
}

resource "aws_ebs_volume" "persistent" {
  availability_zone = local.availability_zone
  type              = "gp3"
  size              = 1
  encrypted         = true
  kms_key_id        = aws_kms_key.doedensonline.arn
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

module "iam_assumable_role_webserver" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  role_name         = "webserver"
  create_role       = true
  role_requires_mfa = false

  trusted_role_arns = [
    "313336455033"
  ]

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  custom_role_policy_arns = [module.ecr_read_only_policy.arn]
}

resource "aws_iam_instance_profile" "webserver" {
  name = "webserver"
  role = module.iam_assumable_role_webserver.iam_role_name
}

module "ec2_instance_doedensonline" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  name                   = "doedensonline"
  ami                    = "ami-0fe0b2cf0e1f25c8a" # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  instance_type          = "t3a.nano"
  subnet_id              = aws_default_subnet.doedensonline.id
  key_name               = "gijs-macbook"
  vpc_security_group_ids = [module.security_group_doedensonline_webserver.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.webserver.name

  ebs_optimized = true
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 10
      encrypted   = true
      kms_key_id  = aws_kms_key.doedensonline.arn
    },
  ]
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
    "webservers" : {
      "hosts" : {
        "main" : {
          "ansible_host" : aws_eip.doedensonline.public_ip,
          "ansible_user" : "ec2-user",
          "smtp_host" : "email-smtp.${local.region}.amazonaws.com",
          "smtp_username" : module.iam_user_doedensonline_ses.iam_access_key_id,
          "smtp_password" : module.iam_user_doedensonline_ses.iam_access_key_ses_smtp_password_v4,
        }
      }
    }
  })
  filename = "${path.module}/inventory.yaml"
}


# AWS SES

resource "aws_ses_domain_identity" "doedensonline" {
  domain = local.domain
}

module "iam_user_doedensonline_ses" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  name                          = "doedensonline-ses"
  create_iam_user_login_profile = false # ?
  password_reset_required       = false
}

resource "aws_iam_user_policy" "allow_ses_sending" {
  name = "AmazonSesSendingAccess"
  user = module.iam_user_doedensonline_ses.iam_user_name

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
  name = "${each.key}._domainkey"
  type = "CNAME"
  ttl  = "60"
  records = ["${each.key}.dkim.amazonses.com"]
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

# Outputs

output "ip" {
  description = "public ip"
  value       = aws_eip.doedensonline.public_ip
}
