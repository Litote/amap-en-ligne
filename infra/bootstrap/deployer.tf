data "aws_region" "current" {}

variable "dynamo_table_name" {
  description = "Name of the single DynamoDB application table (must match infra/ var.dynamo_table_name)"
  type        = string
  default     = "data"
}

# ─── IAM policy for the deployment group ─────────────────────────────────────
# Minimal permissions for terraform apply to create/manage
# all resources declared in infra/ (excluding bootstrap).

data "aws_iam_policy_document" "deployer" {

  # STS — read current identity (aws_caller_identity data source)
  statement {
    sid    = "STS"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }

  # S3 — project buckets (artifacts, web, state): full management of the
  # buckets and their objects. Terraform's bucket refresh reads many sub-config
  # resources (ACL, website, CORS, ownership, …), so the action set is broad but
  # the resource set stays scoped to the project-prefixed bucket names.
  statement {
    sid     = "S3ProjectBuckets"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.project}-*",
      "arn:aws:s3:::${var.project}-*/*"
    ]
  }

  statement {
    sid       = "S3List"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  # DynamoDB — Terraform state lock table + the single application table
  statement {
    sid    = "DynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:UpdateTable",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:UpdateTimeToLive",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:UpdateContinuousBackups",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:ListTagsOfResource",
      # Used by the Terraform backend for locking and the bootstrap server item
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.project}-tflock",
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.dynamo_table_name}",
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.dynamo_table_name}/index/*"
    ]
  }

  # CloudWatch Logs — Lambda and API Gateway log groups
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:ListTagsForResource"
    ]
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*",
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/*"
    ]
  }

  # Account-level CloudWatch Logs actions that do not support resource-level
  # permissions: DescribeLogGroups + the log-delivery API used by API Gateway
  # access logging (aws_apigatewayv2_stage with an access_log_settings block).
  statement {
    sid    = "CloudWatchLogsAccount"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies"
    ]
    resources = ["*"]
  }

  # IAM — Lambda role and policy
  statement {
    sid    = "IAMRolesAndPolicies"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
      "iam:UntagPolicy"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*-lambda-role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project}-*"
    ]
  }

  # IAM PassRole — restricted to Lambda only
  statement {
    sid    = "IAMPassRoleToLambda"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*-lambda-role"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  # Lambda — function, versions, aliases, permissions
  statement {
    sid    = "Lambda"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:PublishVersion",
      "lambda:ListVersionsByFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:CreateAlias",
      "lambda:DeleteAlias",
      "lambda:GetAlias",
      "lambda:UpdateAlias",
      "lambda:ListAliases",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetPolicy",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:ListTags"
    ]
    resources = [
      "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project}-*"
    ]
  }

  # API Gateway v2 — HTTP API, authorizer, integration, routes, stage
  statement {
    sid    = "APIGatewayV2"
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:DELETE",
      "apigateway:TagResource",
      "apigateway:UntagResource"
    ]
    resources = [
      "arn:aws:apigateway:*::/apis",
      "arn:aws:apigateway:*::/apis/*",
      "arn:aws:apigateway:*::/tags/*"
    ]
  }

  # Cognito — User Pool, Resource Server, Client, Domain, Groups
  # ARNs are unknown until creation, so resources = ["*"].
  statement {
    sid    = "CognitoIdp"
    effect = "Allow"
    actions = [
      "cognito-idp:CreateUserPool",
      "cognito-idp:DeleteUserPool",
      "cognito-idp:DescribeUserPool",
      "cognito-idp:UpdateUserPool",
      "cognito-idp:GetUserPoolMfaConfig",
      "cognito-idp:SetUserPoolMfaConfig",
      "cognito-idp:CreateUserPoolClient",
      "cognito-idp:DeleteUserPoolClient",
      "cognito-idp:DescribeUserPoolClient",
      "cognito-idp:UpdateUserPoolClient",
      "cognito-idp:ListUserPoolClients",
      "cognito-idp:CreateUserPoolDomain",
      "cognito-idp:DeleteUserPoolDomain",
      "cognito-idp:DescribeUserPoolDomain",
      "cognito-idp:UpdateUserPoolDomain",
      "cognito-idp:CreateResourceServer",
      "cognito-idp:DeleteResourceServer",
      "cognito-idp:DescribeResourceServer",
      "cognito-idp:UpdateResourceServer",
      "cognito-idp:ListResourceServers",
      "cognito-idp:CreateGroup",
      "cognito-idp:DeleteGroup",
      "cognito-idp:GetGroup",
      "cognito-idp:UpdateGroup",
      "cognito-idp:ListGroups",
      "cognito-idp:TagResource",
      "cognito-idp:UntagResource",
      "cognito-idp:ListTagsForResource",
      "cognito-idp:AddCustomAttributes",
      # Initial owner bootstrap (gated on initial_owner_email)
      "cognito-idp:AdminCreateUser",
      "cognito-idp:AdminDeleteUser",
      "cognito-idp:AdminGetUser",
      "cognito-idp:AdminSetUserPassword",
      "cognito-idp:AdminAddUserToGroup",
      "cognito-idp:AdminRemoveUserFromGroup",
      "cognito-idp:AdminListGroupsForUser"
    ]
    resources = ["*"]
  }

  # SNS — activation-email topic + subscription, and mobile-push platform apps
  statement {
    sid    = "SNS"
    effect = "Allow"
    actions = [
      "sns:CreateTopic",
      "sns:DeleteTopic",
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:ListTagsForResource",
      "sns:TagResource",
      "sns:UntagResource",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:GetSubscriptionAttributes",
      "sns:SetSubscriptionAttributes",
      "sns:ListSubscriptionsByTopic"
    ]
    resources = [
      "arn:aws:sns:*:${data.aws_caller_identity.current.account_id}:${var.project}-*"
    ]
  }

  # SNS platform applications (mobile push) have no project-scoped ARN namespace
  statement {
    sid    = "SNSPlatformApplications"
    effect = "Allow"
    actions = [
      "sns:CreatePlatformApplication",
      "sns:DeletePlatformApplication",
      "sns:GetPlatformApplicationAttributes",
      "sns:SetPlatformApplicationAttributes",
      "sns:ListPlatformApplications"
    ]
    resources = ["*"]
  }

  # SESv2 — sender email identity
  statement {
    sid    = "SESv2"
    effect = "Allow"
    actions = [
      "ses:CreateEmailIdentity",
      "ses:DeleteEmailIdentity",
      "ses:GetEmailIdentity",
      "ses:TagResource",
      "ses:UntagResource",
      "ses:ListTagsForResource"
    ]
    resources = [
      "arn:aws:ses:*:${data.aws_caller_identity.current.account_id}:identity/*"
    ]
  }

  # CloudFront — web distribution, origin access control, response headers
  # policy, cache invalidation. CloudFront create/list actions do not support
  # resource-level permissions, so the resource set is "*". Read-only "Get*"
  # actions are collapsed into a wildcard (also covers GetInvalidation) to keep
  # the managed policy under the 6144-byte IAM size quota; the sensitive
  # create/update/delete actions stay explicit.
  statement {
    sid    = "CloudFront"
    effect = "Allow"
    actions = [
      "cloudfront:Get*",
      "cloudfront:CreateDistribution",
      "cloudfront:CreateDistributionWithTags",
      "cloudfront:UpdateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:TagResource",
      "cloudfront:UntagResource",
      "cloudfront:ListTagsForResource",
      "cloudfront:ListInvalidations",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
      "cloudfront:CreateResponseHeadersPolicy",
      "cloudfront:UpdateResponseHeadersPolicy",
      "cloudfront:DeleteResponseHeadersPolicy",
      "cloudfront:CreateInvalidation"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "deployer" {
  name        = "${var.project}-deployer-policy"
  description = "Terraform permissions to deploy ${var.project}"
  policy      = data.aws_iam_policy_document.deployer.json
}

# IAM group to attach the policy to (optional — attach to your CI users/roles)
resource "aws_iam_group" "deployer" {
  name = "${var.project}-deployer"
}

resource "aws_iam_group_policy_attachment" "deployer" {
  group      = aws_iam_group.deployer.name
  policy_arn = aws_iam_policy.deployer.arn
}

output "deployer_policy_arn" {
  description = "ARN of the IAM policy for the deployment group"
  value       = aws_iam_policy.deployer.arn
}

output "deployer_group_name" {
  description = "Name of the IAM deployment group"
  value       = aws_iam_group.deployer.name
}
