
output "lambda_function_arn" {
  description = "ARN of the created Lambda function"
  value       = module.mikrotik_snmp_lambda.lambda_function_arn
}

output "cloudwatch_namespace" {
  description = "CloudWatch namespace used for the metrics"
  value       = var.cloudwatch_namespace
}
