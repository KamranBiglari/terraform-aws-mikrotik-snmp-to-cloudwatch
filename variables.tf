
variable "router_ip" {
  description = "IP address of the MikroTik router"
  type        = string
}

variable "snmp_communities" {
  description = "List of SNMP community strings to try"
  type        = list(string)
}

variable "snmp_oids" {
  description = "List of SNMP OIDs to poll"
  type        = list(string)
}

variable "cloudwatch_namespace" {
  description = "CloudWatch namespace to use for the metrics"
  type        = string
  default     = "MikroTik"
}

variable "poll_interval" {
  description = "Polling interval in EventBridge rate() expression"
  type        = string
  default     = "rate(5 minutes)"
}

variable "lambda_memory" {
  description = "Lambda memory size"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "enable_verbose_logging" {
  description = "Enable verbose logging (true/false)"
  type        = bool
  default     = false
}
