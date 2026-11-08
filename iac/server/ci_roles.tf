locals {
  ci_role_subjects = {
    pr   = "repo:zeebonk/doedensonline:environment:pr"
    dev  = "repo:zeebonk/doedensonline:environment:dev"
    prod = "repo:zeebonk/doedensonline:environment:prod"
  }
}

data "aws_iam_policy_document" "ci_deploy_state" {
  for_each = local.github_deploy_environments

  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::doedensonline-terraform"]
  }
  statement {
    sid       = "AccessState"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::doedensonline-terraform/env:/${each.key}/deploy"]
  }
  statement {
    sid       = "AccessLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::doedensonline-terraform/env:/${each.key}/deploy.tflock"]
  }
}

resource "aws_iam_policy" "ci_deploy_state" {
  for_each = local.github_deploy_environments
  name     = "GitHubActionsDeployState-${each.key}"
  policy   = data.aws_iam_policy_document.ci_deploy_state[each.key].json
}

module "iam_role_github_actions_ci" {
  for_each = local.ci_role_subjects
  source   = "terraform-aws-modules/iam/aws//modules/iam-role"
  version  = "6.8.2"

  name            = "github-actions-${each.key}"
  use_name_prefix = false
  tags = merge(
    { project = "doedensonline" },
    each.key == "pr" ? {} : { environment = each.key },
  )

  trust_policy_permissions = {
    GitHubActions = {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals = [{
        type        = "Federated"
        identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
      }]
      condition = [
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:aud"
          values   = ["sts.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "token.actions.githubusercontent.com:sub"
          values   = [each.value]
        },
      ]
    }
  }

  policies = merge(
    { ECRPush = module.ecr_push_policy.arn },
    each.key == "pr" ? {} : { DeployState = aws_iam_policy.ci_deploy_state[each.key].arn },
  )
}

resource "github_actions_variable" "aws_role_arn" {
  repository    = "doedensonline"
  variable_name = "AWS_ROLE_ARN"
  value         = module.iam_role_github_actions_ci["pr"].arn
}

resource "github_actions_environment_variable" "aws_role_arn_deploy" {
  for_each      = local.github_deploy_environments
  repository    = "doedensonline"
  environment   = github_repository_environment.deploy[each.key].environment
  variable_name = "AWS_ROLE_ARN"
  value         = module.iam_role_github_actions_ci[each.key].arn
}

resource "github_actions_environment_variable" "aws_role_arn_server" {
  repository    = "doedensonline"
  environment   = "server"
  variable_name = "AWS_ROLE_ARN"
  value         = module.iam_role_github_actions_server.arn
}
