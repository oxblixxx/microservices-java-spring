# Bootstrap uses the same encrypted S3 backend as the environments. The
# bootstrap state bucket itself must exist before `terraform init`; use
# scripts/bootstrap-state.sh to create it, then pass the values below with
# -backend-config=bootstrap.backend.hcl.
terraform {
  backend "s3" {}
}
