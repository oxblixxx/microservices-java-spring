variable "name" {
  description = "Name prefix for the VPC endpoints."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which to create the endpoints."
  type        = string
}

variable "region" {
  description = "AWS region used to build service names when short logical names are supplied."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs used by Interface endpoints (typically the private application subnets)."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security groups attached to Interface endpoints. Required when Interface endpoints are enabled."
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "Route table IDs associated with Gateway endpoints (S3/DynamoDB)."
  type        = list(string)
  default     = []
}

variable "interface_services" {
  description = "Short logical names of Interface endpoints to create (e.g. ecr_api, ecr_dkr, ssm, ssmmessages, ec2messages, logs, secretsmanager, kms)."
  type        = list(string)
  default     = []
}

variable "gateway_services" {
  description = "Short logical names of Gateway endpoints to create (e.g. s3, dynamodb)."
  type        = list(string)
  default     = []
}

variable "custom_endpoints" {
  description = "Additional endpoints keyed by logical name. Use this for service names not present in the built-in service map."
  type = map(object({
    service_name        = string
    vpc_endpoint_type   = string
    private_dns_enabled = optional(bool, true)
    policy              = optional(string, null)
  }))
  default = {}

  validation {
    condition     = alltrue([for v in var.custom_endpoints : contains(["Interface", "Gateway", "GatewayLoadBalancer"], v.vpc_endpoint_type)])
    error_message = "custom_endpoints vpc_endpoint_type must be one of Interface, Gateway or GatewayLoadBalancer."
  }
}

variable "tags" {
  description = "Tags applied to the endpoints."
  type        = map(string)
  default     = {}
}
