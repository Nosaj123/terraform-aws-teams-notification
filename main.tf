#SNS Teams Notifications
data "aws_caller_identity" "current" {}

locals {
  prefix = var.prefix_resource != "" ? "${var.prefix_resource}-" : ""
  function_name = "${local.prefix}Teams-Notification"
}

resource "aws_cloudwatch_log_group" "Teams" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.cloudwatch_log_retention
}

resource "aws_sns_topic" "Teams" {
  name         = local.function_name
  display_name = "Topic used to send sns topic message to Microsoft Teams channel"
}

resource "aws_sns_topic_subscription" "Teams" {
  topic_arn = aws_sns_topic.Teams.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.Teams.arn
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.Teams.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.Teams.arn
}

resource "aws_lambda_function" "Teams" {
  function_name = local.function_name
  memory_size   = 128
  description   = "Send sns topic message to Microsoft Teams channel"
  timeout       = var.function_timeout
  runtime       = "python3.8"
  filename      = "${path.module}/sns-to-teams.zip"
  handler       = "handler.main"
  role          = aws_iam_role.Teams.arn

  environment {
    variables = {
      TEAMS_WEBHOOK_URL = var.teams_webhook_url
      TEAMS_IMAGE_URL   = var.teams_image_url
    }
  }

  #tags = local.tags

  depends_on = [
    aws_sns_topic.Teams,
    aws_cloudwatch_log_group.Teams
  ]
}

data "aws_iam_policy_document" "Teams" {

  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = [
      "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${local.function_name}"
    ]
    actions   = ["lambda:InvokeFunction"]
  }

  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

resource "aws_iam_policy" "Teams" {
  name   = "${local.function_name}-policy"
  policy = data.aws_iam_policy_document.Teams.json
}

resource "aws_iam_role" "Teams" {
  name               = "${local.function_name}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  #tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "Teams" {
  policy_arn = aws_iam_policy.Teams.arn
  role       = aws_iam_role.Teams.name
}