terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }
  }
}

locals {
  # Sensible default: retain the 30 most recent tagged images and expire
  # untagged images after 14 days. Overridable per repository or globally.
  default_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the 30 most recent tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      },
    ]
  })

  effective_lifecycle_policy = {
    for k, repo in var.repositories :
    k => coalesce(repo.lifecycle_policy, var.default_lifecycle_policy, local.default_lifecycle_policy)
  }
}

resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = each.value.name
  image_tag_mutability = each.value.image_tag_mutability
  force_delete         = each.value.force_delete

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  encryption_configuration {
    encryption_type = each.value.encryption_type
    kms_key         = each.value.encryption_type == "KMS" ? each.value.kms_key_arn : null
  }

  tags = merge(var.tags, each.value.tags, { Name = each.value.name })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = local.effective_lifecycle_policy

  repository = aws_ecr_repository.this[each.key].name
  policy     = each.value
}

resource "aws_ecr_repository_policy" "this" {
  for_each = { for k, repo in var.repositories : k => repo if repo.repository_policy != null }

  repository = aws_ecr_repository.this[each.key].name
  policy     = each.value.repository_policy
}
