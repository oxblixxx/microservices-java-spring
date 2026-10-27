variable "name" {
  description = "Name prefix for the NAT gateways and their Elastic IPs."
  type        = string
}

variable "enabled" {
  description = "Whether NAT gateways are created. Keep disabled when private egress is served exclusively by VPC endpoints."
  type        = bool
  default     = false
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used to host the NAT gateways."
  type        = list(string)
  default     = []
}

variable "per_az" {
  description = "When true a NAT gateway is created in every public subnet; when false a single NAT gateway is created in the first public subnet."
  type        = bool
  default     = true
}

variable "connectivity_type" {
  description = "NAT gateway connectivity type: public or private."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.connectivity_type)
    error_message = "connectivity_type must be either public or private."
  }
}

variable "tags" {
  description = "Tags applied to NAT gateway resources."
  type        = map(string)
  default     = {}
}
