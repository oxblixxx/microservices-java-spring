# ---------------------------------------------------------------------------
# Packer plugins.
#
# Run `packer init .` to download these. Version constraints are pinned to the
# current major line so a build only picks up backwards-compatible releases.
#   - amazon  v1.8.3 (2026-10-07)
#   - ansible v1.1.6 (2026-07-14)
# ---------------------------------------------------------------------------
packer {
  required_version = ">= 1.10.0"

  required_plugins {
    amazon = {
      version = ">= 1.8.0, < 2.0.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.0, < 2.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# ---------------------------------------------------------------------------
# Source: official Canonical Ubuntu 24.04 LTS cloud image.
#
# The AMI is resolved dynamically by owner + name + EBS/HVM/architecture
# attributes; no AMI ID is hardcoded. Packer logs the resolved image
# ("Found image ID: ami-...") and it is recorded in the build manifest.
#
# Connection model: direct SSH over the temporary instance's public IP. Packer
# creates a temporary key pair and (by default) a temporary security group that
# allows inbound TCP 22 only from the public IP of the machine running Packer.
# No SSM tunnel is used for the build.
# ---------------------------------------------------------------------------
source "amazon-ebs" "ubuntu_base" {
  region = var.aws_region

  instance_type = var.build_instance_type

  # The temporary instance is launched into a subnet that supports public IP
  # assignment and has a route to an Internet Gateway so Packer can reach it on
  # SSH. build_subnet_id / build_vpc_id are retained as inputs; the resulting
  # AMI is not tied to either.
  subnet_id = var.build_subnet_id != "" ? var.build_subnet_id : null
  vpc_id    = var.build_vpc_id != "" ? var.build_vpc_id : null

  # Give the temporary instance a public IP so the direct-SSH communicator can
  # reach it. This is a build-instance setting only; it is not baked into the
  # AMI, and the final EC2 instances do not require public IPs.
  associate_public_ip_address = true

  # Restrict temporary SSH access:
  #   * By default (no build_security_group_ids) Packer creates a temporary
  #     security group whose inbound rule allows TCP/22 only from the public IP
  #     detected for the machine running Packer.
  #   * If build_security_group_ids is supplied, Packer does not create a
  #     temporary group; those groups must already allow SSH from the
  #     controller's public IP. 0.0.0.0/0 is never used here.
  security_group_ids                        = length(var.build_security_group_ids) > 0 ? var.build_security_group_ids : null
  temporary_security_group_source_public_ip = true

  # Optional instance profile for the temporary build instance. Not required for
  # a direct-SSH build and never attached to the resulting AMI: Terraform
  # attaches the runtime profile when it launches instances from the AMI.
  iam_instance_profile = var.build_instance_profile != "" ? var.build_instance_profile : null

  # --- Source image -------------------------------------------------------
  source_ami_filter {
    filters = {
      name                = local.source_ami_name_filter
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = local.aws_architecture
      state               = "available"
    }
    owners      = [var.source_ami_owner]
    most_recent = true
  }

  # --- Communicator -------------------------------------------------------
  communicator  = "ssh"
  ssh_interface = var.ssh_interface
  ssh_username  = var.ssh_username
  ssh_timeout   = var.ssh_timeout

  # Remove Packer's temporary SSH key from authorized_keys after provisioning.
  ssh_clear_authorized_keys = true

  # --- IMDS ---------------------------------------------------------------
  # Enforce IMDSv2 on the running build instance and on AMIs launched from the
  # resulting image. Hop limit 1 keeps the metadata service out of reach of
  # containers on the default bridge.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.enforce_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = 1
  }
  imds_support = var.enforce_imdsv2 ? "v2.0" : null

  # --- Root volume --------------------------------------------------------
  launch_block_device_mappings {
    device_name           = var.root_volume_device_name
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = var.delete_on_termination
    encrypted             = var.encrypt_boot
  }

  ami_block_device_mappings {
    device_name           = var.root_volume_device_name
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = var.delete_on_termination
  }

  encrypt_boot = var.encrypt_boot
  kms_key_id   = var.kms_key_id != "" ? var.kms_key_id : null

  # --- Resulting AMI ------------------------------------------------------
  ami_name        = local.ami_name
  ami_description = local.ami_description

  # Inside the builder the source AMI is exposed through Go template syntax; the
  # same values are available as build.SourceAMI* in the manifest custom_data.
  tags = merge(local.ami_tags, {
    SourceAMI     = "{{ .SourceAMI }}"
    SourceAMIName = "{{ .SourceAMIName }}"
  })
  snapshot_tags = local.ami_tags
  run_tags      = local.run_tags
}

# ---------------------------------------------------------------------------
# Build: configure the temporary instance with the Ansible provisioner, then
# emit a machine-readable manifest.
#
# The standard `ansible` provisioner runs ansible-playbook on THIS machine and
# connects to the build instance over SSH (ssh_interface = public_ip). use_proxy
# routes Ansible through Packer's own SSH communicator adapter, which is the
# provisioner's normal connectivity model; it is not SSM-specific.
# ---------------------------------------------------------------------------
build {
  name    = "ubuntu-base"
  sources = ["source.amazon-ebs.ubuntu_base"]

  provisioner "ansible" {
    playbook_file = local.ansible_playbook
    galaxy_file   = local.ansible_galaxy_file

    command        = var.ansible_command
    galaxy_command = var.ansible_galaxy_command

    # Packer always connects as the communicator user; the ansible provisioner
    # otherwise defaults to the local user running Packer.
    user = var.ssh_username

    host_alias = "packer_build"
    groups     = ["packer_build"]

    # Route Ansible through Packer's local SSH communicator adapter. This is the
    # ansible provisioner's default connectivity model and works with the
    # direct public-IP SSH communicator used for this build.
    use_proxy = true

    ansible_env_vars = [
      "ANSIBLE_CONFIG=${local.ansible_config}",
      "ANSIBLE_ROLES_PATH=${local.ansible_dir}/roles",
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_NOCOLOR=True",
      "ANSIBLE_PYTHON_INTERPRETER=auto_silent",
      # Keep all remote temporary files under /tmp so the cleanup role removes
      # them along with the rest of the build scratch space.
      #"ANSIBLE_REMOTE_TEMP=/tmp/.ansible-remote",
    ]

    extra_arguments = concat(
      [
        "--extra-vars",
        jsonencode({
          aws_region               = var.aws_region
          build_date               = local.build_date
          image_role               = var.image_role
          image_version            = local.image_version
          project_name             = var.project_name
          ubuntu_release           = var.ubuntu_release
          apply_security_updates   = var.apply_security_updates
          install_aws_cli          = var.install_aws_cli
          docker_log_max_size      = var.docker_log_max_size
          docker_log_max_file      = var.docker_log_max_file
          cloudwatch_agent_enabled = var.cloudwatch_agent
        }),
      ],
      local.ansible_verbosity_flags,
    )
  }

  post-processor "manifest" {
    output     = local.manifest_path
    strip_path = true

    custom_data = {
      Project       = var.project_name
      ImageRole     = var.image_role
      ImageVersion  = local.image_version
      BaseOS        = local.base_os
      BuildDate     = local.build_date
      Architecture  = var.architecture
      BuildRegion   = var.aws_region
      BuildName     = "ubuntu-base"
      SourceAMI     = "${build.SourceAMI}"
      SourceAMIName = "${build.SourceAMIName}"
    }
  }
}
