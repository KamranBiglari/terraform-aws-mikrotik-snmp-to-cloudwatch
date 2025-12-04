
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

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for Lambda VPC configuration. Leave empty to run Lambda outside VPC"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for Lambda VPC configuration. Leave empty if create_security_group is true"
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Create a security group for Lambda. Only used if vpc_subnet_ids is provided and vpc_security_group_ids is empty"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for creating security group. Required if create_security_group is true"
  type        = string
  default     = ""
}

variable "resource_prefix" {
  description = "Prefix to add to all resource names. If empty, uses default naming"
  type        = string
  default     = ""
}
