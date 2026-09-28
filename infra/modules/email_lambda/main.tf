# ─── CloudWatch Log Group ─────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "activation_email" {
  name              = "/aws/lambda/${var.name}-activation-email"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ─── IAM Role ─────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "email_lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "email_lambda" {
  name               = "${var.name}-email-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.email_lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "email_lambda_basic" {
  role       = aws_iam_role.email_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SES policy: allow sending emails

data "aws_iam_policy_document" "email_lambda_ses" {
  statement {
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "email_lambda_ses" {
  name   = "${var.name}-email-lambda-ses"
  policy = data.aws_iam_policy_document.email_lambda_ses.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "email_lambda_ses" {
  role       = aws_iam_role.email_lambda.name
  policy_arn = aws_iam_policy.email_lambda_ses.arn
}

# ─── Lambda Function (GraalVM native, custom runtime) ────────────────────────

resource "aws_lambda_function" "activation_email" {
  function_name = "${var.name}-activation-email"
  role          = aws_iam_role.email_lambda.arn

  s3_bucket         = var.jar_s3_bucket
  s3_key            = var.jar_s3_key
  s3_object_version = var.jar_s3_object_version

  handler     = "deploy.lambda.ActivationEmailMainKt"
  runtime     = "provided.al2023"
  memory_size = var.memory_mb
  timeout     = var.timeout_seconds

  publish = true

  environment {
    variables = {
      KOIN_LOG_LEVEL = var.koin_log_level
      SES_FROM_EMAIL = var.ses_from_email
    }
  }

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.activation_email,
    aws_iam_role_policy_attachment.email_lambda_basic,
  ]
}

# ─── Alias "live" → published version ────────────────────────────────────────

resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.activation_email.function_name
  function_version = aws_lambda_function.activation_email.version
}

# ─── SNS → Lambda subscription and permission ────────────────────────────────

resource "aws_sns_topic_subscription" "activation_email" {
  protocol  = "lambda"
  topic_arn = var.sns_topic_arn
  endpoint  = aws_lambda_alias.live.arn
}

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.activation_email.function_name
  qualifier     = aws_lambda_alias.live.name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}
