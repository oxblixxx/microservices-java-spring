# ---------------------------------------------------------------------------
# Derived values shared by the source and build blocks.
# ---------------------------------------------------------------------------

locals {
  # Build metadata. timestamp() is evaluated when the template is loaded, so a
  # single build gets a stable version/date even though it is generated at run
  # time rather than hardcoded.
  build_timestamp = timestamp()
  build_date      = formatdate("YYYY-MM-DD", local.build_timestamp)
  build_id        = formatdate("YYYYMMDDhhmmss", local.build_timestamp)

  image_version = var.image_version != "" ? var.image_version : local.build_id

  ami_name = "${var.ami_name_prefix}-${local.image_version}"

  base_os = "ubuntu-${var.ubuntu_release}"

  # Canonical publishes Ubuntu server cloud images under hvm-ssd-gp3 for
  # 24.04/noble. The name is only a filter: the actual source AMI is resolved
  # dynamically by owner + name + EBS/HVM/arch attributes at build time.
  source_ami_name_filter = (
    var.source_ami_name_filter != ""
    ? var.source_ami_name_filter
    : "ubuntu/images/hvm-ssd-gp3/ubuntu-${var.ubuntu_codename}-${var.ubuntu_release}-${var.architecture}-server-*"
  )

  # Packer calls the CPU architecture "amd64"/"arm64"; the EC2 DescribeImages
  # filter expects "x86_64"/"arm64".
  aws_architecture = var.architecture == "amd64" ? "x86_64" : "arm64"

  ami_description = (
    var.ami_description != ""
    ? var.ami_description
    : "Container-host base image (${local.base_os}, ${var.architecture}) built with Packer for ${var.project_name}."
  )

  # Tags applied to the AMI and its snapshots. SourceAMI/SourceAMIName are added
  # in the source block because they are Packer build template data resolved at
  # build time, not at template-evaluation time.
  common_tags = {
    Project      = var.project_name
    ManagedBy    = "packer"
    ImageRole    = var.image_role
    BaseOS       = local.base_os
    Version      = local.image_version
    BuildDate    = local.build_date
    Architecture = var.architecture
    BuildRegion  = var.aws_region
  }

  optional_tags = merge(
    var.owner != "" ? { Owner = var.owner } : {},
    var.cost_center != "" ? { CostCenter = var.cost_center } : {},
    var.environment != "" ? { Environment = var.environment } : {},
  )

  ami_tags = merge(
    local.common_tags,
    local.optional_tags,
    var.additional_tags,
    { Name = local.ami_name },
  )

  # Tags for the temporary resources Packer launches (instance, volumes, key
  # pair, temporary security group). Clearly marked so they can be identified
  # and cleaned up if a build fails.
  run_tags = merge(local.ami_tags, { Name = "packer-build-${local.build_id}" })

  # Ansible assets. path.root is the directory of this root template.
  ansible_dir         = "${path.root}/ansible"
  ansible_playbook    = "${local.ansible_dir}/playbook.yml"
  ansible_config      = "${local.ansible_dir}/ansible.cfg"
  ansible_galaxy_file = "${local.ansible_dir}/requirements.yml"

  # Ansible verbosity flags, kept as an explicit map because HCL has no repeat.
  ansible_verbosity_flags = lookup(
    {
      "0" = []
      "1" = ["-v"]
      "2" = ["-vv"]
      "3" = ["-vvv"]
      "4" = ["-vvvv"]
    },
    format("%d", var.ansible_verbosity),
    [],
  )

  manifest_path = "${path.root}/${var.manifest_output}"
}
