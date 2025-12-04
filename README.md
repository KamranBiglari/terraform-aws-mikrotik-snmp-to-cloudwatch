# Terraform AWS MikroTik SNMP to CloudWatch

Get SNMP metrics from your MikroTik router (or any SNMP-capable device) into CloudWatch without managing servers. This module sets up a Lambda function that polls your devices and ships metrics to CloudWatch on a schedule.

## What it does

Deploys a serverless SNMP poller using:
- Lambda function (Python) for SNMP polling
- EventBridge to trigger polling on your schedule
- IAM roles with minimal required permissions
- Optional VPC support for private networks
- Optional security group management

## Why use this?

SNMP monitoring usually means running Nagios, Zabbix, or some other monitoring server. That's overkill if you just want a few metrics in CloudWatch. This module gives you SNMP polling without the ops overhead.

Works great if you:
- Have MikroTik routers and want metrics in AWS
- Need to monitor network gear from Lambda
- Want SNMP metrics alongside your other CloudWatch data
- Don't want to manage monitoring infrastructure

## Quick Start

Basic setup - Lambda can reach your router directly:

```hcl
module "mikrotik_snmp" {
  source  = "KamranBiglari/mikrotik-snmp-to-cloudwatch/aws"
  version = "~> 1.0"

  router_ip            = "192.168.88.1"
  snmp_communities     = ["private"]
  cloudwatch_namespace = "MikroTik"
  poll_interval        = "rate(5 minutes)"

  snmp_oids = [
    "1.3.6.1.2.1.1.3.0",           # uptime
    "1.3.6.1.4.1.14988.1.1.3.10.0", # CPU
    "1.3.6.1.2.1.2.2.1.16.1",       # bytes out
    "1.3.6.1.2.1.2.2.1.10.1",       # bytes in
  ]
}
```

## VPC Setup

If your router is on a private network, run Lambda in your VPC:

```hcl
module "mikrotik_snmp_vpc" {
  source  = "KamranBiglari/mikrotik-snmp-to-cloudwatch/aws"
  version = "~> 1.0"

  router_ip            = "10.0.1.100"
  snmp_communities     = ["monitoring"]
  cloudwatch_namespace = "NetworkDevices"
  
  vpc_subnet_ids        = ["subnet-12345678", "subnet-87654321"]
  create_security_group = true
  vpc_id                = "vpc-abcdef12"

  lambda_timeout         = 60
  enable_verbose_logging = true  # helpful during setup

  snmp_oids = [
    "1.3.6.1.2.1.1.3.0",
    "1.3.6.1.4.1.14988.1.1.3.10.0",
  ]
}
```

**Note:** When using VPC mode, make sure your subnets can route to your router and have NAT gateway access (Lambda needs internet to send CloudWatch metrics).

## Useful MikroTik OIDs

Some OIDs I've found helpful:

| OID | What it measures |
|-----|------------------|
| `1.3.6.1.2.1.1.3.0` | System uptime |
| `1.3.6.1.4.1.14988.1.1.3.10.0` | CPU load (%) |
| `1.3.6.1.2.1.2.2.1.10.1` | Bytes in on first interface |
| `1.3.6.1.2.1.2.2.1.16.1` | Bytes out on first interface |
| `1.3.6.1.4.1.14988.1.1.1.6.1.0` | Board temperature |

You can find more OIDs by browsing your router's SNMP tree or checking MikroTik's documentation.

## Requirements

- Terraform >= 1.5.7
- AWS Provider >= 5.0
- Docker (module builds the Lambda zip using a container)
- Your Lambda needs to reach the SNMP device on UDP port 161

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mikrotik_snmp_lambda"></a> [mikrotik\_snmp\_lambda](#module\_mikrotik\_snmp\_lambda) | terraform-aws-modules/lambda/aws | ~> 8.0 |
| <a name="module_snmp_poll_schedule"></a> [snmp\_poll\_schedule](#module\_snmp\_poll\_schedule) | terraform-aws-modules/eventbridge/aws | ~> 2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_security_group.lambda_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_namespace"></a> [cloudwatch\_namespace](#input\_cloudwatch\_namespace) | CloudWatch namespace to use for the metrics | `string` | `"MikroTik"` | no |
| <a name="input_create_poll_schedule"></a> [create\_poll\_schedule](#input\_create\_poll\_schedule) | Create EventBridge schedule to poll SNMP | `bool` | `true` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Create a security group for Lambda. Only used if vpc\_subnet\_ids is provided and vpc\_security\_group\_ids is empty | `bool` | `false` | no |
| <a name="input_enable_verbose_logging"></a> [enable\_verbose\_logging](#input\_enable\_verbose\_logging) | Enable verbose logging (true/false) | `bool` | `false` | no |
| <a name="input_lambda_memory"></a> [lambda\_memory](#input\_lambda\_memory) | Lambda memory size | `number` | `128` | no |
| <a name="input_lambda_timeout"></a> [lambda\_timeout](#input\_lambda\_timeout) | Lambda timeout in seconds | `number` | `30` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix for all resources | `string` | `"mikrotik-snmp"` | no |
| <a name="input_poll_enabled"></a> [poll\_enabled](#input\_poll\_enabled) | Enable or disable polling | `bool` | `true` | no |
| <a name="input_poll_interval"></a> [poll\_interval](#input\_poll\_interval) | Polling interval in EventBridge rate() expression | `string` | `"rate(5 minutes)"` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to add to all resource names. If empty, uses default naming | `string` | `""` | no |
| <a name="input_router_ip"></a> [router\_ip](#input\_router\_ip) | IP address of the MikroTik router | `string` | n/a | yes |
| <a name="input_snmp_communities"></a> [snmp\_communities](#input\_snmp\_communities) | List of SNMP community strings to try | `list(string)` | n/a | yes |
| <a name="input_snmp_oids"></a> [snmp\_oids](#input\_snmp\_oids) | List of SNMP OIDs to poll | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for creating security group. Required if create\_security\_group is true | `string` | `""` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of security group IDs for Lambda VPC configuration. Leave empty if create\_security\_group is true | `list(string)` | `[]` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | List of subnet IDs for Lambda VPC configuration. Leave empty to run Lambda outside VPC | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_namespace"></a> [cloudwatch\_namespace](#output\_cloudwatch\_namespace) | CloudWatch namespace used for the metrics |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the created Lambda function |
| <a name="output_lambda_security_group_id"></a> [lambda\_security\_group\_id](#output\_lambda\_security\_group\_id) | Security group ID of the Lambda function (if created) |
| <a name="output_snmp_poll_schedule"></a> [snmp\_poll\_schedule](#output\_snmp\_poll\_schedule) | Scheduler Event for polling SNMP |
<!-- END_TF_DOCS -->

## Troubleshooting

**Lambda can't reach my device**

Check the basics first:
- Is SNMP enabled on your device?
- Is the community string correct?
- Security groups allowing UDP 161?
- If using VPC: does Lambda's subnet route to the device?

Turn on verbose logging to see what's happening:
```hcl
enable_verbose_logging = true
```

**No metrics in CloudWatch**

Usually means SNMP polling works but something's wrong with the OIDs:
- Check CloudWatch Logs for the Lambda function
- Verify OIDs are valid for your device (try `snmpwalk` from your machine)
- Make sure the OIDs return numeric values

**Lambda timing out**

- Bump up `lambda_timeout` (default is 30s)
- Poll fewer OIDs per run
- Check network latency to your device

## What you'll pay

Typical costs for polling every 5 minutes:
- Lambda: Free tier covers ~8,600 invocations/month, so likely $0
- CloudWatch custom metrics: $0.30/metric/month
- CloudWatch Logs: Usually under $1/month
- EventBridge: Free for scheduled rules

Total: Probably $1-3/month unless you're polling many devices.

## Examples

Check [examples/basic/](./examples/basic/) for a complete working example.

## Planned improvements

- SNMP v3 support
- Friendlier metric names (nobody wants to remember OIDs)
- Multi-device polling
- Better error handling

## License

MIT

## Author

Kamran Biglari
