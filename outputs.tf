output "lambda_arn" {
  value       = aws_lambda_function.Teams.arn
  description = "The Lambda ARN who send SNS topic message to Microsoft Teams"
}

output "sns_arn" {
  value       = aws_sns_topic.Teams.arn
  description = "The SNS ARN who send SNS topic message to Microsoft Teams"
}

output "role_arn" {
  value       = aws_iam_role.Teams.arn
  description = "The IAM Role ARN used by Lambda who send SNS topic message to Microsoft Teams"
}