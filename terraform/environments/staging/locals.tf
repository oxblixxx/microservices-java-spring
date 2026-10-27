locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = var.owner
      CostCenter  = var.cost_center
    },
    var.additional_tags,
  )

  # Logical service keys shared by ECR, image parameters and (in production)
  # ECS. The api-gateway is the only service that may be exposed publicly.
  service_keys = [
    "api_gateway",
    "patient_service",
    "billing_service",
    "auth_service",
    "analytics_service",
  ]

  ecr_repositories = {
    for key in local.service_keys : key => {
      name                 = replace(key, "_", "-")
      image_tag_mutability = var.ecr_image_tag_mutability
      scan_on_push         = false
      encryption_type      = "AES256"
      force_delete         = var.ecr_force_delete
    }
  }

  # Resolve the image reference for each service. Values from
  # var.application_images are surfaced verbatim (tag or digest); they are never
  # used to deploy anything in staging.
  application_images = {
    for key in local.service_keys : key => lookup(var.application_images, key, "")
  }
}
