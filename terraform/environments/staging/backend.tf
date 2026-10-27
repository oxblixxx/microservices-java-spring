# Remote state for the staging environment. Values are supplied at init time
# via -backend-config (see staging.backend.hcl.example). Native S3 locking is
# used (use_lockfile = true); no DynamoDB table is required.
terraform {
  backend "s3" {}
}
