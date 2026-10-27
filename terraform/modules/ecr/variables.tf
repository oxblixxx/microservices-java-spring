variable "repositories" {
  description = "Map of logical repository key to ECR repository configuration."
  type = map(object({
    name                 = string
    image_tag_mutability = optional(string, "IMMUTABLE")
    scan_on_push         = optional(bool, true)
    encryption_type      = optional(string, "KMS")
    kms_key_arn          = optional(string, null)
    force_delete         = optional(bool, false)
    lifecycle_policy     = optional(string, null)
    repository_policy    = optional(string, null)
    tags                 = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.repositories) : contains(["MUTABLE", "IMMUTABLE"], r.image_tag_mutability)
    ])
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }

  validation {
    condition = alltrue([
      for r in values(var.repositories) : contains(["AES256", "KMS"], r.encryption_type)
    ])
    error_message = "encryption_type must be AES256 or KMS."
  }
}

variable "default_lifecycle_policy" {
  description = "Optional lifecycle policy JSON applied to repositories that do not define their own."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to all repositories."
  type        = map(string)
  default     = {}
}
