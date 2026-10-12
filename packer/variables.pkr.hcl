# ---------------------------------------------------------------------------
# Source image and identity
#
# Every variable can be supplied at build time via a PKR_VAR_* environment
# variable (for example PKR_VAR_aws_region=eu-west-1) or an auto-loaded
# *.auto.pkrvars.hcl file. See ubuntu-base.auto.pkrvars.example.hcl.
# ---------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "AWS region the AMI is built in. Should match the region of the staging EC2 hosts."
  default     = "eu-west-1"
}

variable "project_name" {
  type        = string
  description = "Project name used for AMI naming and tagging."
  default     = "microservices-java-spring"
}

variable "image_role" {
  type        = string
  description = "Logical role of the image. Both staging hosts (microservices and platform) use the same container-host base image."
  default     = "container-host-base"
}

variable "image_version" {
  type        = string
  description = "Version or build identifier embedded in the AMI name and the Version tag. When empty a UTC timestamp is generated at build time."
  default     = ""
}

variable "ami_name_prefix" {
  type        = string
  description = "Prefix for the resulting AMI name. The image version/build identifier is appended to make the name unique."
  default     = "microservices-java-spring-container-host-base"
}

variable "ami_description" {
  type        = string
  description = "Description applied to the resulting AMI. When empty a description is derived from the image metadata."
  default     = ""
}

# ---------------------------------------------------------------------------
# Source AMI selection
# ---------------------------------------------------------------------------

variable "source_ami_owner" {
  type        = string
  description = "AWS account ID of the trusted source AMI owner. 099720109477 is Canonical Group Limited (official Ubuntu cloud images)."
  default     = "099720109477"
}

variable "ubuntu_release" {
  type        = string
  description = "Ubuntu release used for the source AMI name filter and the BaseOS tag."
  default     = "24.04"
}

variable "ubuntu_codename" {
  type        = string
  description = "Ubuntu codename used in Canonical AMI names (24.04 = noble)."
  default     = "noble"
}

variable "source_ami_name_filter" {
  type        = string
  description = "AMI name glob used to resolve the newest source image. When empty a Canonical name is derived from the release, codename and architecture."
  default     = ""
}

variable "architecture" {
  type        = string
  description = "Target CPU architecture. amd64 matches the current staging instance types."
  default     = "amd64"

  validation {
    condition     = contains(["amd64", "arm64"], var.architecture)
    error_message = "Architecture must be either amd64 or arm64."
  }
}

# ---------------------------------------------------------------------------
# Temporary build instance and direct-SSH connectivity
# ---------------------------------------------------------------------------

variable "build_instance_type" {
  type        = string
  description = "Instance type of the temporary build instance. A small general-purpose type is sufficient."
  default     = "t3.micro"
}

variable "build_subnet_id" {
  type        = string
  description = "Subnet the temporary build instance is launched in. Required for a real build. For direct SSH the subnet must support public IP assignment and have a route to an Internet Gateway (a public subnet), and it must be able to reach the package repositories."
  default     = ""
}

variable "build_vpc_id" {
  type        = string
  description = "VPC ID of build_subnet_id. Required by Packer when it creates its temporary security group (i.e. when build_security_group_ids is empty)."
  default     = ""
}

variable "build_security_group_ids" {
  type        = list(string)
  description = "Optional existing security group IDs to attach to the build instance. Leave empty (recommended) so Packer creates a temporary security group that allows SSH only from the controller's public IP. If supplied, these groups must already allow inbound TCP/22 from the controller's public IP; Packer will not create a temporary group and does not use 0.0.0.0/0."
  default     = []
}

variable "build_instance_profile" {
  type        = string
  description = "Optional IAM instance profile for the temporary build instance. Not required for a direct-SSH build (the connection does not use SSM) and never attached to the resulting AMI. Leave empty to launch the builder without a profile."
  default     = ""
}

variable "ssh_interface" {
  type        = string
  description = "Communicator interface used to reach the build instance. public_ip (default) connects directly to the temporary instance's public IP."
  default     = "public_ip"

  validation {
    condition     = contains(["public_ip", "private_ip", "public_dns", "private_dns", "session_manager"], var.ssh_interface)
    error_message = "Ssh_interface must be one of public_ip, private_ip, public_dns, private_dns or session_manager."
  }
}

variable "ssh_username" {
  type        = string
  description = "SSH user for the build instance. Canonical Ubuntu images use the 'ubuntu' user."
  default     = "ubuntu"
}

variable "ssh_timeout" {
  type        = string
  description = "How long Packer waits for the SSH communicator to become available."
  default     = "15m"
}

# ---------------------------------------------------------------------------
# Root EBS volume / AMI encryption
# ---------------------------------------------------------------------------

variable "root_volume_size" {
  type        = number
  description = "Size in GiB of the root EBS volume baked into the AMI. Must be at least the size of the source AMI's root volume."
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "Root_volume_size must be at least 8 GiB."
  }
}

variable "root_volume_type" {
  type        = string
  description = "EBS volume type for the root volume."
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "st1", "sc1", "standard"], var.root_volume_type)
    error_message = "Root_volume_type must be a valid EBS volume type."
  }
}

variable "root_volume_device_name" {
  type        = string
  description = "Root device name reported by the Canonical Ubuntu source AMI."
  default     = "/dev/sda1"
}

variable "delete_on_termination" {
  type        = bool
  description = "Whether the root EBS volume is deleted when the temporary build instance is terminated. True is recommended to avoid leaving orphaned volumes."
  default     = true
}

variable "encrypt_boot" {
  type        = bool
  description = "Encrypt the resulting AMI's root snapshot. Uses the region default EBS key unless kms_key_id is set."
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "Optional KMS key ID, alias or ARN used to encrypt the resulting AMI. Empty uses the AWS-managed EBS key for the region."
  default     = ""
}

variable "enforce_imdsv2" {
  type        = bool
  description = "Enforce IMDSv2 on the temporary build instance and on instances launched from the resulting AMI."
  default     = true
}

# ---------------------------------------------------------------------------
# Ansible provisioning (runs locally, from this machine)
# ---------------------------------------------------------------------------

variable "ansible_command" {
  type        = string
  description = "Executable used to run the playbook. Point this at a wrapper script or virtualenv binary when ansible-playbook is not on PATH."
  default     = "ansible-playbook"
}

variable "ansible_galaxy_command" {
  type        = string
  description = "Executable used to resolve ansible/requirements.yml before provisioning."
  default     = "ansible-galaxy"
}

variable "ansible_verbosity" {
  type        = number
  description = "Ansible verbosity level (0-4). 0 keeps normal output; 2 or higher is useful when debugging SSH connectivity to the build instance."
  default     = 0

  validation {
    condition     = var.ansible_verbosity >= 0 && var.ansible_verbosity <= 4
    error_message = "Ansible_verbosity must be between 0 and 4."
  }
}

# ---------------------------------------------------------------------------
# Software configuration forwarded to Ansible
# ---------------------------------------------------------------------------

variable "apply_security_updates" {
  type        = bool
  description = "Apply available package/security updates during the build."
  default     = true
}

variable "install_aws_cli" {
  type        = bool
  description = "Install AWS CLI v2 from the official AWS installer. Off by default to keep the package set minimal; ECR pulls work without it via the ECR credential helper."
  default     = false
}

variable "docker_log_max_size" {
  type        = string
  description = "Maximum size of an individual container log file before rotation (Docker json-file driver)."
  default     = "10m"
}

variable "docker_log_max_file" {
  type        = string
  description = "Number of rotated container log files to retain (Docker json-file driver)."
  default     = "3"
}

variable "cloudwatch_agent" {
  type        = bool
  description = "Install the CloudWatch Agent. No CloudWatch resources, credentials or environment-specific configuration are baked into the image."
  default     = false
}

# ---------------------------------------------------------------------------
# Tags and build artifact
# ---------------------------------------------------------------------------

variable "owner" {
  type        = string
  description = "Optional Owner tag. Empty omits the tag."
  default     = ""
}

variable "cost_center" {
  type        = string
  description = "Optional CostCenter tag. Empty omits the tag."
  default     = ""
}

variable "environment" {
  type        = string
  description = "Optional Environment tag. Usually left empty because this is a reusable base image."
  default     = ""
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags applied to the AMI and its snapshots."
  default     = {}
}

variable "manifest_output" {
  type        = string
  description = "File name of the machine-readable build manifest, written next to this template."
  default     = "packer-manifest.json"
}
