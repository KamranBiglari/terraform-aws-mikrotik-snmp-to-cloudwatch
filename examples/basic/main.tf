
module "mikrotik_snmp_to_cloudwatch" {
  source = "../../"

  router_ip              = "192.168.88.1"
  snmp_communities       = ["private", "public"]
  cloudwatch_namespace   = "MikroTik"
  poll_interval          = "rate(5 minutes)"
  lambda_memory          = 128
  lambda_timeout         = 30
  enable_verbose_logging = true

  snmp_oids = [
    "1.3.6.1.2.1.1.3.0",
    "1.3.6.1.4.1.14988.1.1.3.10.0",
    "1.3.6.1.2.1.2.2.1.16.1",
    "1.3.6.1.2.1.2.2.1.10.1",
    "1.3.6.1.4.1.14988.1.1.1.6.1.0"
  ]
}
