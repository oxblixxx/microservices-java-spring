variable "roles" {
  description = "Map of logical role key to IAM role configuration. Assume role and inline policies are supplied as JSON documents."
  type = map(object({
    name                 = string
    description          = optional(string, "")
    path                 = optional(string, "/")
    assume_role_policy   = string
    managed_policy_arns  = optional(list(string), [])
    permissions_boundary = optional(string, null)
    max_session_duration = optional(number, 3600)
    tags                 = optional(map(string), {})
    inline_policies = optional(map(object({
      description = optional(string, "")
      policy      = string
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.roles) : r.max_session_duration >= 3600 && r.max_session_duration <= 43200
    ])
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "instance_profiles" {
  description = "Map of logical instance profile key to its configuration. role_key must reference a key in var.roles."
  type = map(object({
    name     = string
    role_key = string
    path     = optional(string, "/")
    tags     = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Common tags applied to all IAM resources."
  type        = map(string)
  default     = {}
}
