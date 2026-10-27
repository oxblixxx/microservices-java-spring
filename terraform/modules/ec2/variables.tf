variable "instances" {
  description = "Map of logical instance key to its configuration. Instances are created in the private subnet supplied via subnet_id and never receive a public IP unless explicitly requested."
  type = map(object({
    instance_type               = string
    subnet_id                   = string
    name                        = optional(string, null)
    ami                         = optional(string, null)
    security_group_ids          = optional(list(string), [])
    iam_instance_profile        = optional(string, null)
    key_name                    = optional(string, null)
    associate_public_ip_address = optional(bool, false)
    user_data                   = optional(string, null)
    user_data_base64            = optional(string, null)
    user_data_replace_on_change = optional(bool, false)
    monitoring                  = optional(bool, false)
    ebs_optimized               = optional(bool, null)
    disable_api_termination     = optional(bool, false)
    tags                        = optional(map(string), {})
    metadata_options = optional(object({
      http_endpoint               = optional(string, "enabled")
      http_tokens                 = optional(string, "required")
      http_put_response_hop_limit = optional(number, 1)
      instance_metadata_tags      = optional(string, "disabled")
    }), {})
    root_volume = optional(object({
      size                  = optional(number, 30)
      type                  = optional(string, "gp3")
      iops                  = optional(number, null)
      throughput            = optional(number, null)
      encrypted             = optional(bool, true)
      kms_key_id            = optional(string, null)
      delete_on_termination = optional(bool, true)
    }), {})
  }))

  validation {
    condition = alltrue([
      for i in values(var.instances) : contains(["enabled", "disabled"], i.metadata_options.http_endpoint)
    ])
    error_message = "metadata_options.http_endpoint must be enabled or disabled."
  }

  validation {
    condition = alltrue([
      for i in values(var.instances) : contains(["optional", "required"], i.metadata_options.http_tokens)
    ])
    error_message = "metadata_options.http_tokens must be optional or required."
  }
}

variable "ami_id" {
  description = "Explicit AMI ID applied when an instance does not override it. When null the latest matching Amazon Linux 2023 AMI is used."
  type        = string
  default     = null
}

variable "ami_owners" {
  description = "AMI owners used when resolving the default AMI."
  type        = list(string)
  default     = ["amazon"]
}

variable "ami_name_filter" {
  description = "AMI name filter used when resolving the default Amazon Linux 2023 AMI."
  type        = string
  default     = "al2023-ami-*-x86_64"
}

variable "ami_architecture" {
  description = "AMI architecture used when resolving the default AMI."
  type        = string
  default     = "x86_64"
}

variable "tags" {
  description = "Common tags applied to all instances."
  type        = map(string)
  default     = {}
}
