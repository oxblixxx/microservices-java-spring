variable "name" {
  description = "Name prefix for the VPC and its associated resources."
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "enable_dns_support" {
  description = "Whether DNS resolution is supported in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Whether instances receive DNS hostnames."
  type        = bool
  default     = true
}

variable "manage_default_security_group" {
  description = "When true the VPC default security group is managed with no rules (deny all)."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Whether VPC Flow Logs are published to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_logs_traffic_type" {
  description = "Traffic type captured by flow logs. One of ACCEPT, REJECT or ALL."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "flow_logs_traffic_type must be one of ACCEPT, REJECT or ALL."
  }
}

variable "flow_logs_retention_days" {
  description = "Retention period (days) for the flow logs CloudWatch log group."
  type        = number
  default     = 30
}

variable "flow_logs_kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt the flow logs log group."
  type        = string
  default     = null
}

variable "flow_logs_log_group_name" {
  description = "Optional explicit name for the flow logs log group."
  type        = string
  default     = null
}

variable "flow_logs_max_aggregation_interval" {
  description = "Maximum interval (seconds) during which flow log data is aggregated. One of 60 or 600."
  type        = number
  default     = 60

  validation {
    condition     = contains([60, 600], var.flow_logs_max_aggregation_interval)
    error_message = "flow_logs_max_aggregation_interval must be 60 or 600."
  }
}

variable "tags" {
  description = "Tags applied to all resources in the module."
  type        = map(string)
  default     = {}
}
