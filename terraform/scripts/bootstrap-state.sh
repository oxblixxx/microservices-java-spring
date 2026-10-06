#!/usr/bin/env bash
#
# Creates the S3 bucket that stores the *bootstrap* Terraform state.
#
# This must run before `terraform init` in terraform/bootstrap because the
# bootstrap stack uses the same encrypted S3 backend it manages for the other
# environments (avoiding the classic state-bucket chicken-and-egg problem).
#
# Native S3 conditional writes provide state locking, so no DynamoDB table is
# created.
#
# Usage: scripts/bootstrap-state.sh <bucket-name> [region]

set -euo pipefail

BUCKET="microservices-patient-$(openssl rand -hex 4)"
REGION="${2:-${AWS_REGION:-eu-west-1}}"

if [[ -z "$BUCKET" ]]; then
  echo "usage: $0 <bucket-name> [region]" >&2
  exit 1
fi

echo "Ensuring state bucket '${BUCKET}' exists in ${REGION}..."

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Bucket already exists."
else
  create_args=(--bucket "$BUCKET" --region "$REGION")
  if [[ "$REGION" != "us-east-1" ]]; then
    create_args+=(--create-bucket-configuration "LocationConstraint=${REGION}")
  fi
  aws s3api create-bucket "${create_args[@]}"
fi

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'

aws s3api put-bucket-ownership-controls \
  --bucket "$BUCKET" \
  --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]' || true

echo "State bucket ready: s3://${BUCKET}"
echo "Next: copy bootstrap/bootstrap.backend.hcl.example and run scripts/init-backend.sh bootstrap"
