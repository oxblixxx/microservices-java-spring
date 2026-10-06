variable "project" {
  description = "Project name used for tagging and resource naming."
  type        = string
}

variable "owner" {
  description = "Owning team or individual."
  type        = string
}

variable "cost_center" {
  description = "Cost center associated with the resources."
  type        = string
}

variable "region" {
  description = "AWS region for the bootstrap resources and state buckets."
  type        = string
}

variable "additional_tags" {
  description = "Additional tags merged into every resource."
  type        = map(string)
  default     = {}
}

variable "create_state_kms_key" {
  description = "Whether to create a dedicated KMS key for Terraform state encryption."
  type        = bool
  default     = true
}

variable "kms_deletion_window_in_days" {
  description = "Deletion window for the state KMS key."
  type        = number
  default     = 30
}

variable "state_buckets" {
  description = "Map of environment key to its Terraform state S3 bucket configuration. Bucket names must be globally unique."
  type = map(object({
    name          = string
    force_destroy = optional(bool, false)
  }))
}

variable "noncurrent_state_version_expiration_days" {
  description = "Days after which noncurrent state object versions expire."
  type        = number
  default     = 90
}

variable "create_github_oidc_provider" {
  description = "Whether to create the GitHub Actions OIDC provider. Only one is needed per AWS account."
  type        = bool
  default     = true
}

variable "github_oidc_thumbprints" {
  description = "Thumbprints for the GitHub Actions OIDC provider. AWS manages the GitHub certificate chain; these well-known values satisfy the API."
  type        = list(string)
  default = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}
