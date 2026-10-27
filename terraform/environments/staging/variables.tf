variable "project" {
  description = "Project name used for naming and tagging."
  type        = string
  default     = "microservices-java-spring"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "staging"

  validation {
    condition     = var.environment == "staging"
    error_message = "This stack manages the staging environment only."
  }
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "terraform_state_bucket" {
  description = "Name of the S3 bucket holding the staging Terraform state. Used to scope the GitHub Actions role. Leave empty to omit state permissions."
  type        = string
  default     = ""
}

variable "terraform_state_kms_key_arn" {
  description = "ARN of the KMS key encrypting the staging Terraform state. Used to scope the GitHub Actions role."
  type        = string
  default     = null
}

variable "owner" {
  description = "Owning team or individual."
  type        = string
}

variable "cost_center" {
  description = "Cost center associated with the resources."
  type        = string
}

variable "additional_tags" {
  description = "Additional tags merged into every resource."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "network" {
  description = "Network layout for the staging VPC."
  type = object({
    cidr                     = string
    azs                      = list(string)
    public_subnets           = list(string)
    private_subnets          = list(string)
    management_subnets       = optional(list(string), [])
    enable_flow_logs         = optional(bool, true)
    flow_logs_retention_days = optional(number, 30)
    map_public_ip_on_launch  = optional(bool, false)
  })

  validation {
    condition     = length(var.network.azs) >= 1 && length(var.network.private_subnets) >= 1
    error_message = "At least one availability zone and one private subnet are required."
  }

  validation {
    condition     = length(var.network.public_subnets) == 0 || length(var.network.public_subnets) == length(var.network.azs)
    error_message = "Provide either no public subnets or exactly one per availability zone."
  }
}

variable "nat" {
  description = "NAT gateway configuration. Disabled by default; enable when the EC2 hosts need outbound Internet access (Docker package installation, image pulls)."
  type = object({
    enabled = optional(bool, false)
    per_az  = optional(bool, false)
  })
  default = {}
}

variable "vpc_endpoints" {
  description = "VPC endpoints to create. Interface endpoints are placed in the private subnets; gateway endpoints are associated with the private route tables."
  type = object({
    interface_services = optional(list(string), [])
    gateway_services   = optional(list(string), [])
    custom = optional(map(object({
      service_name        = string
      vpc_endpoint_type   = string
      private_dns_enabled = optional(bool, true)
      policy              = optional(string, null)
    })), {})
  })
  default = {}
}

# ---------------------------------------------------------------------------
# EC2 hosts
# ---------------------------------------------------------------------------

variable "ec2" {
  description = "Staging EC2 host configuration. Both hosts are placed in private subnets with no public IP."
  type = object({
    microservices = object({
      instance_type                 = string
      volume_size                   = number
      volume_type                   = optional(string, "gp3")
      ami_id                        = optional(string, null)
      additional_security_group_ids = optional(list(string), [])
    })
    platform = object({
      instance_type                 = string
      volume_size                   = number
      volume_type                   = optional(string, "gp3")
      ami_id                        = optional(string, null)
      additional_security_group_ids = optional(list(string), [])
    })
    management = object({
      instance_type                 = string
      volume_size                   = number
      volume_type                   = optional(string, "gp3")
      ami_id                        = optional(string, null)
      additional_security_group_ids = optional(list(string), [])
    })

  })

  validation {
    condition     = var.ec2.microservices.volume_size >= 8 && var.ec2.platform.volume_size >= 8 && var.ec2.management.volume_size >= 8
    error_message = "Root volume sizes must be at least 8 GiB."
  }
}

# ---------------------------------------------------------------------------
# Container images
# ---------------------------------------------------------------------------

variable "application_images" {
  description = "Map of logical service key to a container image reference (ECR tag or immutable digest). Empty by default; values are surfaced as outputs and SSM parameters and are never used to deploy workloads in staging."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.application_images : contains(["api_gateway", "patient_service", "billing_service", "auth_service", "analytics_service"], k)
    ])
    error_message = "application_images keys must be one of api_gateway, patient_service, billing_service, auth_service, analytics_service."
  }
}

variable "ecr_image_tag_mutability" {
  description = "Image tag mutability for the staging ECR repositories."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "ecr_image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "ecr_force_delete" {
  description = "Whether ECR repositories are force-deleted when removed from state."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Twingate private access layer
# ---------------------------------------------------------------------------

variable "twingate" {
  description = "Optional Twingate connector configuration. Disabled by default."
  type = object({
    enabled                     = optional(bool, false)
    connector_count             = optional(number, 1)
    instance_type               = optional(string, "t3.micro")
    ami_id                      = optional(string, null)
    token_ssm_parameter_name    = optional(string, "/twingate/connector-token")
    token_kms_key_arn           = optional(string, null)
    connector_image             = optional(string, "twingate/connector:1")
    associate_public_ip_address = optional(bool, false)
  })
  default = {}

  validation {
    condition     = var.twingate.connector_count >= 1 && var.twingate.connector_count <= 2
    error_message = "twingate.connector_count must be 1 or 2."
  }
}

# ---------------------------------------------------------------------------
# Observability hooks
# ---------------------------------------------------------------------------

variable "observability" {
  description = "Observability wiring for externally managed SigNoz/OpenTelemetry."
  type = object({
    otlp_endpoint      = optional(string, "")
    otlp_protocol      = optional(string, "grpc")
    log_retention_days = optional(number, 30)
  })
  default = {}
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC
# ---------------------------------------------------------------------------

variable "github_actions" {
  description = "GitHub Actions OIDC role for this environment."
  type = object({
    enabled            = optional(bool, true)
    oidc_provider_arn  = optional(string, null)
    repository         = optional(string, null)
    subject_claims     = optional(list(string), [])
    role_name          = optional(string, null)
    inline_policy_json = optional(string, null)
  })
  default = {}

  validation {
    condition     = !var.github_actions.enabled || var.github_actions.oidc_provider_arn != null
    error_message = "github_actions.oidc_provider_arn is required when the GitHub Actions role is enabled (create it with the bootstrap stack)."
  }

  validation {
    condition     = !var.github_actions.enabled || var.github_actions.repository != null
    error_message = "github_actions.repository (org/repo) is required when the GitHub Actions role is enabled."
  }
}
