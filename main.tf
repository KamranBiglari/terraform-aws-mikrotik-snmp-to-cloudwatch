
module "mikrotik_snmp_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0"

  function_name = "mikrotik-snmp-to-cloudwatch-${var.router_ip}"
  description   = "Lambda to poll MikroTik SNMP and push to CloudWatch"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  publish       = true

  source_path = "${path.module}/lambda_src"

  memory_size = var.lambda_memory
  timeout     = var.lambda_timeout

  environment_variables = {
    ROUTER_IP            = var.router_ip
    SNMP_COMMUNITIES     = join(",", var.snmp_communities)
    SNMP_OIDS            = join(",", var.snmp_oids)
    CLOUDWATCH_NAMESPACE = var.cloudwatch_namespace
    VERBOSE_LOGGING      = tostring(var.enable_verbose_logging)
  }

  attach_cloudwatch_logs_policy = true
}

module "snmp_poll_schedule" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "~> 2.0"

  create = true

  rules = {
    "poll-mikrotik" = {
      description         = "Trigger MikroTik SNMP poll Lambda"
      schedule_expression = var.poll_interval
      enabled             = true
    }
  }

  targets = {
    "poll-mikrotik" = [
      {
        arn = module.mikrotik_snmp_lambda.lambda_function_arn
        id  = "MikroTikPollTarget"
      }
    ]
  }
}
