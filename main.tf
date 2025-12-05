locals {
  create_sg          = var.create_security_group && length(var.vpc_subnet_ids) > 0 && length(var.vpc_security_group_ids) == 0
  use_vpc            = length(var.vpc_subnet_ids) > 0
  security_group_ids = local.create_sg ? [aws_security_group.lambda_sg[0].id] : var.vpc_security_group_ids
  name_prefix        = var.resource_prefix != "" ? "${var.resource_prefix}-" : ""
  router_suffix      = replace(var.router_ip, ".", "-")
}

resource "aws_security_group" "lambda_sg" {
  count       = local.create_sg ? 1 : 0
  name        = "${local.name_prefix}${var.name}-lambda-${local.router_suffix}-sg"
  description = "Security group for MikroTik SNMP Lambda"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}${var.name}-lambda-${local.router_suffix}-sg"
  }
}

module "mikrotik_snmp_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = "${local.name_prefix}${var.name}-cw-${local.router_suffix}"
  description   = "Lambda to poll MikroTik SNMP and push to CloudWatch"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  publish       = true

  source_path = [
    {
      path             = "${path.module}/lambda_src"
      pip_requirements = true
      patterns = [
        "!\\.terragrunt-.*",
        "!.*\\.pyc"
      ]
    }
  ]

  build_in_docker = true
  docker_image    = "public.ecr.aws/sam/build-python3.12:latest"
  docker_file     = "${path.module}/lambda_src/Dockerfile"

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

  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })

  vpc_subnet_ids         = local.use_vpc ? var.vpc_subnet_ids : null
  vpc_security_group_ids = local.use_vpc ? local.security_group_ids : null
  attach_network_policy  = local.use_vpc

  allowed_triggers = {
    ScanAmiRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.snmp_poll_schedule.eventbridge_rule_arns["${var.resource_prefix}${var.name}-poll"]
    }
  }

}

module "snmp_poll_schedule" {
  count   = var.create_poll_schedule ? 1 : 0
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "~> 2.0"

  create     = true
  create_bus = false

  role_name = "${local.name_prefix}${var.name}-cw-${local.router_suffix}-eb-role"

  rules = {
    "${var.resource_prefix}${var.name}-poll" = {
      description         = "Trigger MikroTik SNMP poll Lambda"
      schedule_expression = var.poll_interval
      state               = var.poll_enabled ? "ENABLED" : "DISABLED"
    }
  }

  targets = {
    "${var.resource_prefix}${var.name}-poll" = [
      {
        name = "MikroTikPollTarget"
        arn  = module.mikrotik_snmp_lambda.lambda_function_arn
      }
    ]
  }
}
