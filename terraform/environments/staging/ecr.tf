# Private ECR repositories, one per microservice. Images are not deployed by
# Terraform; CI/CD pushes to these repositories and resolves the immutable
# digest that the deployment layer consumes.
module "ecr" {
  source = "../../modules/ecr"

  repositories = local.ecr_repositories

  tags = local.common_tags
}
