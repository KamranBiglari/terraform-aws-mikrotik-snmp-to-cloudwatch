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

```bash
terraform-docs markdown table --output-file README.md --output-mode inject /path/to/module
```

## VPC Setup

### Using docker

terraform-docs can be run as a container by mounting a directory with `.tf`
files in it and run the following command:

```bash
docker run --rm --volume "$(pwd):/terraform-docs" -u $(id -u) quay.io/terraform-docs/terraform-docs:0.17.0 markdown /terraform-docs
```

If `output.file` is not enabled for this module, generated output can be redirected
back to a file:



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