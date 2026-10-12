# ---------------------------------------------------------------------------
# Example build variables for the container-host base AMI.
#
# Copy this file to ubuntu-base.auto.pkrvars.hcl (which Packer auto-loads and
# .gitignore excludes) and replace the placeholder subnet values with real ones
# from your AWS account.
#
#   cp ubuntu-base.auto.pkrvars.example.hcl ubuntu-base.auto.pkrvars.hcl
#
# Alternatively pass individual values as PKR_VAR_* environment variables, e.g.
#   PKR_VAR_build_subnet_id=subnet-0123456789abcdef0 packer build .
#
# Do NOT commit real account IDs, subnet IDs, profile names or secrets.
# ---------------------------------------------------------------------------

# --- Identity --------------------------------------------------------------
aws_region      = "us-east-1"
project_name    = "microservices-java-spring"
image_role      = "container-host-base"
image_version   = "" # empty -> generated UTC timestamp, e.g. 20261010t143012

ami_name_prefix = "microservices-java-spring-container-host-base"

# --- Source image ----------------------------------------------------------
ubuntu_release = "24.04"
ubuntu_codename = "noble"
architecture    = "amd64"
source_ami_owner = "099720109477" # Canonical Group Limited
# source_ami_name_filter = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"

# --- Temporary build instance (direct SSH) ---------------------------------
# Direct SSH build: the temporary instance gets a public IP and Packer connects
# on TCP/22. The build subnet must therefore support public IP assignment and
# have a route to an Internet Gateway (a public subnet). build_vpc_id is needed
# by Packer when it creates its temporary security group.
build_instance_type = "t3.micro"
build_subnet_id     = "subnet-REPLACE-WITH-PUBLIC-BUILD-SUBNET-ID"
build_vpc_id        = "vpc-REPLACE-WITH-VPC-ID"

# Recommended: leave empty so Packer creates a temporary security group that
# allows SSH only from the public IP of the machine running Packer
# (temporary_security_group_source_public_ip). If you must reuse existing
# security groups, they have to allow inbound TCP/22 from that public IP.
# build_security_group_ids = ["sg-REPLACE-WITH-CONTROLLER-RESTRICTED-SG-ID"]

# Optional instance profile for the temporary build instance. Not required for a
# direct-SSH build (the connection does not use SSM). Leave empty for no profile.
# build_instance_profile = "REPLACE-WITH-OPTIONAL-BUILD-PROFILE"

ssh_interface = "public_ip"
ssh_username  = "ubuntu"

# --- Root volume / AMI -----------------------------------------------------
root_volume_size  = 20
root_volume_type  = "gp3"
encrypt_boot      = true
# kms_key_id      = "alias/REPLACE-WITH-KMS-ALIAS"
enforce_imdsv2    = true

# --- Software --------------------------------------------------------------
apply_security_updates = true
install_aws_cli        = false
docker_log_max_size    = "10m"
docker_log_max_file    = "3"
cloudwatch_agent       = false

# --- Tags ------------------------------------------------------------------
owner       = "platform-team"
cost_center = "engineering"
# environment = "staging"  # normally left empty; this is a reusable base image

additional_tags = {
  # Example: Budget = "platform"
}

# --- Build artifact --------------------------------------------------------
manifest_output = "packer-manifest.json"
