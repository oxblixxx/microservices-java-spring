variable "name" {
  description = "Name prefix for the route tables."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway used for public egress."
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "Public subnet IDs associated with the public route table."
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "Private subnet IDs associated with private route tables."
  type        = list(string)
  default     = []
}

variable "management_subnet_ids" {
  description = "Optional management subnet IDs associated with the management route table."
  type        = list(string)
  default     = []
}

variable "create_public_route_table" {
  description = "Whether to create and associate a public route table."
  type        = bool
  default     = true
}

variable "nat_gateway_ids" {
  description = "NAT gateway IDs available for private egress."
  type        = list(string)
  default     = []
}

variable "public_default_route" {
  description = "Default route target for public subnets: igw or none."
  type        = string
  default     = "igw"

  validation {
    condition     = contains(["igw", "none"], var.public_default_route)
    error_message = "public_default_route must be either igw or none."
  }
}

variable "private_default_route" {
  description = "Default route target for private subnets: nat or none. Use none when egress is provided exclusively by VPC endpoints."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["nat", "none"], var.private_default_route)
    error_message = "private_default_route must be either nat or none."
  }
}

variable "management_default_route" {
  description = "Default route target for the optional management subnet: igw, nat or none."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["igw", "nat", "none"], var.management_default_route)
    error_message = "management_default_route must be one of igw, nat or none."
  }
}

variable "tags" {
  description = "Tags applied to route tables."
  type        = map(string)
  default     = {}
}
