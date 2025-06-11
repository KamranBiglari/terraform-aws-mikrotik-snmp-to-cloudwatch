
# terraform-aws-mikrotik-snmp-to-cloudwatch

Terraform module to deploy an AWS Lambda function that polls SNMP OIDs from a MikroTik router (or any SNMP device) and pushes the results to CloudWatch Metrics.

## Features

- Supports arbitrary list of SNMP OIDs
- Supports multiple SNMP community strings (tries them in order)
- Metrics are published to configurable CloudWatch namespace
- Simple EventBridge rule to schedule polling at fixed intervals
- Reusable for any SNMP v2c-capable device (not just MikroTik)
- Verbose logging toggle for debugging

## Usage

```hcl
module "mikrotik_snmp_to_cloudwatch" {
  source  = "kamranbiglari/mikrotik-snmp-to-cloudwatch/aws"

  router_ip                = "192.168.88.1"
  snmp_communities         = ["private", "public"]
  cloudwatch_namespace     = "MikroTik"
  poll_interval            = "rate(5 minutes)"
  lambda_memory            = 128
  lambda_timeout           = 30
  enable_verbose_logging   = true

  snmp_oids = [
    "1.3.6.1.2.1.1.3.0",
    "1.3.6.1.4.1.14988.1.1.3.10.0",
    "1.3.6.1.2.1.2.2.1.16.1",
    "1.3.6.1.2.1.2.2.1.10.1",
    "1.3.6.1.4.1.14988.1.1.1.6.1.0"
  ]
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| router_ip | IP address of the MikroTik router | string | n/a |
| snmp_communities | List of SNMP community strings to try | list(string) | n/a |
| snmp_oids | List of SNMP OIDs to poll | list(string) | n/a |
| cloudwatch_namespace | CloudWatch namespace to use for the metrics | string | "MikroTik" |
| poll_interval | Polling interval (EventBridge rate expression) | string | "rate(5 minutes)" |
| lambda_memory | Lambda memory size | number | 128 |
| lambda_timeout | Lambda timeout in seconds | number | 30 |
| enable_verbose_logging | Enable verbose logging | bool | false |

## Outputs

| Name | Description |
|------|-------------|
| lambda_function_arn | ARN of the created Lambda function |
| cloudwatch_namespace | CloudWatch namespace used for the metrics |

## Roadmap

- Add SNMP v3 support (future version)
- Add per-OID unit and friendly name mapping (future version)

## License

MIT License
