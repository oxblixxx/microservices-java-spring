# ---------------------------------------------------------------------------
# Assume-role policies
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "github_assume" {
  count = var.github_actions.enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.github_actions.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = length(var.github_actions.subject_claims) > 0 ? var.github_actions.subject_claims : [
        "repo:${var.github_actions.repository}:ref:refs/heads/main",
        "repo:${var.github_actions.repository}:pull_request",
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# Shared EC2 SSM role for both staging hosts. Permissions are limited to SSM
# Session Manager, CloudWatch agent publishing, ECR image pull, reading this
# environment's configuration parameters and decrypting this environment's
# secrets.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "ec2_app" {
  statement {
    sid    = "ReadEnvironmentParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${local.name_prefix}/*",
    ]
  }

  # The former "WriteApplicationLogs" statement is intentionally omitted: its
  # `resources` referenced the observability module's log groups, which are
  # disabled in staging, leaving a statement with no resources that IAM rejects
  # with MalformedPolicyDocument. CloudWatch Logs writes are already granted by
  # the attached CloudWatchAgentServerPolicy managed policy. Restore a scoped
  # statement here if the observability log groups are re-enabled.
  statement {
    sid       = "EcrAuthorization"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # statement {
  #   sid    = "ReadApplicationSecrets"
  #   effect = "Allow"
  #   actions = [
  #     "secretsmanager:GetSecretValue",
  #     "secretsmanager:DescribeSecret",
  #   ]
  #   resources = [for arn in values(module.secrets.secret_arns) : arn]
#  }

  # statement {
  #   sid       = "DecryptSecrets"
  #   effect    = "Allow"
  #   actions   = ["kms:Decrypt", "kms:DescribeKey"]
  #   resources = [module.kms_secrets.key_arn]
  # }
}

# ---------------------------------------------------------------------------
# Default GitHub Actions Terraform/deployment policy. Supply
# github_actions.inline_policy_json to replace it entirely.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "github_default" {
  count = var.github_actions.enabled ? 1 : 0

  dynamic "statement" {
    for_each = var.terraform_state_bucket != "" ? [var.terraform_state_bucket] : []
    content {
      sid       = "TerraformStateList"
      effect    = "Allow"
      actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
      resources = ["arn:${data.aws_partition.current.partition}:s3:::${statement.value}"]
    }
  }

  dynamic "statement" {
    for_each = var.terraform_state_bucket != "" ? [var.terraform_state_bucket] : []
    content {
      sid       = "TerraformStateObjects"
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = ["arn:${data.aws_partition.current.partition}:s3:::${statement.value}/${var.environment}/*"]
    }
  }

  dynamic "statement" {
    for_each = var.terraform_state_kms_key_arn != null ? [var.terraform_state_kms_key_arn] : []
    content {
      sid       = "TerraformStateKms"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
      resources = [statement.value]
    }
  }

  statement {
    sid    = "ManageStagingInfrastructure"
    effect = "Allow"
    actions = [
      "ec2:*",
      "ecr:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "logs:*",
      "cloudwatch:*",
      "ssm:*",
      "kms:*",
      "secretsmanager:*",
      "tag:GetResources",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:GetInstanceProfile",
      "iam:PassRole",
    ]
    resources = ["*"]
  }
}

module "iam" {
  source = "../../modules/iam"

  roles = merge(
    {
      ec2_ssm = {
        name               = "${local.name_prefix}-ec2-ssm"
        description        = "SSM-managed staging EC2 hosts"
        assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
        managed_policy_arns = [
          "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
          "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy",
          "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        ]
        inline_policies = {
          app = {
            policy = data.aws_iam_policy_document.ec2_app.json
          }
        }
      }
    },
    var.github_actions.enabled ? {
      github_actions = {
        name               = coalesce(var.github_actions.role_name, "${local.name_prefix}-github-actions")
        description        = "GitHub Actions OIDC role for ${local.name_prefix}"
        assume_role_policy = data.aws_iam_policy_document.github_assume[0].json
        inline_policies = {
          default = {
            policy = coalesce(var.github_actions.inline_policy_json, data.aws_iam_policy_document.github_default[0].json)
          }
        }
      }
    } : {},
  )

  instance_profiles = {
    ec2_ssm = {
      name     = "${local.name_prefix}-ec2-ssm"
      role_key = "ec2_ssm"
    }
  }

  tags = local.common_tags
}
