# ─── GitHub Actions OIDC deploy role ─────────────────────────────────────────
# Lets the deploy workflow assume an AWS role via OIDC (no long-lived keys).
# The role carries the same deployer permissions as the CI group.
#
# These resources already exist in AWS (created out-of-band); they are imported
# into the bootstrap state rather than recreated. See README for the import
# commands.

variable "github_repo" {
  description = "GitHub repository allowed to assume the deploy role (owner/name)"
  type        = string
  default     = "Litote/amap-en-ligne"
}

# OIDC identity provider for GitHub Actions tokens.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9514f4ed3c841c96c43def0f0acbf177405ded12"]
}

# Trust policy: only the production environment (deploy) and pull_request
# (terraform plan) subjects of this repository may assume the role.
# The `production` environment is itself restricted to the `main` branch by a
# GitHub deployment branch policy, so deploys can only originate from `main`.
data "aws_iam_policy_document" "github_actions_deploy_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        # `production` environment = the automatic dev deploy on push to main;
        # `prod` environment = the manual prod deploy (separate AWS account).
        # Each account's role only ever sees the subjects of jobs that target it;
        # listing both is harmless and keeps one bootstrap codebase per account.
        "repo:${var.github_repo}:environment:production",
        "repo:${var.github_repo}:environment:prod",
        "repo:${var.github_repo}:pull_request"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "github-actions-deploy-lambda"
  description        = "Role for GitHub Actions to deploy Lambda functions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_deploy_assume_role.json
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.deployer.arn
}

output "github_actions_deploy_role_arn" {
  description = "ARN of the role assumed by the GitHub Actions deploy workflow"
  value       = aws_iam_role.github_actions_deploy.arn
}
