variable "name" {
  description = "Name prefix for the subnets."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which to create the subnets."
  type        = string
}

variable "azs" {
  description = "Availability zones used to spread subnets. Subnets are distributed round-robin across this list."
  type        = list(string)

  validation {
    condition     = length(var.azs) > 0
    error_message = "At least one availability zone must be provided."
  }
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one entry per subnet)."
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "CIDR blocks for private/application subnets (one entry per subnet)."
  type        = list(string)
  default     = []
}

variable "management_subnets" {
  description = "CIDR blocks for optional management subnets (one entry per subnet)."
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Whether public/management subnets auto-assign public IPs. Private subnets never do."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all subnets."
  type        = map(string)
  default     = {}
}
