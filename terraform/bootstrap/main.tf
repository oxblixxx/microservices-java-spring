locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = "bootstrap"
      ManagedBy   = "terraform"
      Component   = "terraform-state"
      Owner       = var.owner
      CostCenter  = var.cost_center
    },
    var.additional_tags,
  )
}

# ---------------------------------------------------------------------------
# KMS key used to encrypt every Terraform state object (all environments).
# ---------------------------------------------------------------------------

resource "aws_kms_key" "state" {
  count = var.create_state_kms_key ? 1 : 0

  description             = "Terraform remote state encryption for ${var.project}"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.state[0].json

  tags = merge(local.common_tags, { Name = "${var.project}-terraform-state" })
}

resource "aws_kms_alias" "state" {
  count = var.create_state_kms_key ? 1 : 0

  name          = "alias/${var.project}-terraform-state"
  target_key_id = aws_kms_key.state[0].key_id
}

data "aws_iam_policy_document" "state" {
  count = var.create_state_kms_key ? 1 : 0

  statement {
    sid       = "EnableRootAccountAdmin"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

# ---------------------------------------------------------------------------
# S3 state buckets: one per environment (bootstrap, staging, production).
# Native S3 conditional writes provide state locking (use_lockfile = true), so
# no DynamoDB table is created.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "state" {
  for_each = var.state_buckets

  bucket        = each.value.name
  force_destroy = try(each.value.force_destroy, false)

  tags = merge(local.common_tags, { Name = each.value.name, Purpose = "terraform-state" })
}

resource "aws_s3_bucket_versioning" "state" {
  for_each = var.state_buckets

  bucket = aws_s3_bucket.state[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  for_each = var.state_buckets

  bucket = aws_s3_bucket.state[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.create_state_kms_key ? "aws:kms" : "AES256"
      kms_master_key_id = var.create_state_kms_key ? aws_kms_key.state[0].arn : null
    }
    bucket_key_enabled = var.create_state_kms_key
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  for_each = var.state_buckets

  bucket = aws_s3_bucket.state[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  for_each = var.state_buckets

  bucket = aws_s3_bucket.state[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "state_bucket" {
  for_each = var.state_buckets

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.state[each.key].arn,
      "${aws_s3_bucket.state[each.key].arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  for_each = var.state_buckets

  bucket = aws_s3_bucket.state[each.key].id
  policy = data.aws_iam_policy_document.state_bucket[each.key].json

  depends_on = [aws_s3_bucket_public_access_block.state]
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  for_each = var.state_buckets

  bucket = aws_s3_bucket.state[each.key].id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_state_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC provider (one per AWS account).
# ---------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.github_oidc_thumbprints

  tags = merge(local.common_tags, { Name = "github-actions-oidc" })
}
