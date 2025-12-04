
output "lambda_function_arn" {
  description = "ARN of the created Lambda function"
  value       = module.mikrotik_snmp_lambda.lambda_function_arn
}

output "cloudwatch_namespace" {
  description = "CloudWatch namespace used for the metrics"
  value       = var.cloudwatch_namespace
}

output "lambda_security_group_id" {
  description = "Security group ID of the Lambda function (if created)"
  value       = local.create_sg ? aws_security_group.lambda_sg[0].id : null
}

output "snmp_poll_schedule" {
  description = "Scheduler Event for polling SNMP"
  value       = var.create_poll_schedule ? module.snmp_poll_schedule[0] : null
}
