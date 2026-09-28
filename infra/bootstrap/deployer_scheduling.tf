# Scheduled jobs (EventBridge rules triggering Lambdas, e.g. the volunteer shortage
# alerts). Kept in a separate managed policy: the main deployer policy is at the
# 6144-byte managed-policy size limit.
data "aws_iam_policy_document" "deployer_scheduling" {
  statement {
    sid    = "EventBridgeRules"
    effect = "Allow"
    actions = [
      "events:PutRule",
      "events:DeleteRule",
      "events:DescribeRule",
      "events:EnableRule",
      "events:DisableRule",
      "events:PutTargets",
      "events:RemoveTargets",
      "events:ListTargetsByRule",
      "events:ListTagsForResource",
      "events:TagResource",
      "events:UntagResource",
    ]
    resources = [
      "arn:aws:events:*:${data.aws_caller_identity.current.account_id}:rule/${var.project}-*"
    ]
  }
}

resource "aws_iam_policy" "deployer_scheduling" {
  name        = "${var.project}-deployer-scheduling-policy"
  description = "Terraform permissions to deploy the scheduled jobs of ${var.project}"
  policy      = data.aws_iam_policy_document.deployer_scheduling.json
}

resource "aws_iam_group_policy_attachment" "deployer_scheduling" {
  group      = aws_iam_group.deployer.name
  policy_arn = aws_iam_policy.deployer_scheduling.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy_scheduling" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.deployer_scheduling.arn
}
