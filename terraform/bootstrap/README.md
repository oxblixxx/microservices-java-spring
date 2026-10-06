# Bootstrap stack

Creates the account-level prerequisites that the staging and production stacks
depend on:

- One encrypted, versioned, public-access-blocked **S3 bucket per environment**
  for Terraform remote state (bootstrap, staging, production)
- A customer-managed **KMS key** used to encrypt state objects
- The **GitHub Actions OIDC provider** (one per AWS account)

Bootstrap itself uses the bucket created with [bootstrap-script](microservices-java-spring/terraform/script/bootstrap-state.sh), which must exist
before `terraform init`, it is created first with the `scripts/bootstrap-state.sh`
helper.

## Procedure

```bash
# 1. Create the bootstrap state bucket with the AWS CLI.
../scripts/bootstrap-state.sh my-org-project-name-terraform-state-bootstrap eu-west-1

# 2. Configure the backend.
cp bootstrap.backend.hcl.example bootstrap.backend.hcl

# 3. Configure variables.
cp terraform.tfvars.example terraform.tfvars

# 4. Init and apply.
terraform init -backend-config=bootstrap.backend.hcl
terraform apply

# 5. Record the outputs for the environment stacks.
terraform output
```

`github_oidc_provider_arn` is consumed by the `github_actions.oidc_provider_arn`
variable of both environment stacks. The bucket names and KMS key ARN feed the
`*.backend.hcl` files and the `terraform_state_bucket` /
`terraform_state_kms_key_arn` variables.

## State locking

State locking uses S3 conditional writes (`use_lockfile = true`). No DynamoDB
table is created.
