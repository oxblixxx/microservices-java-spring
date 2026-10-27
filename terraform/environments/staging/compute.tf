# Two private EC2 hosts: one for the microservices runtime, one for the
# observability/messaging workloads. Neither host receives a public IP and
# neither is reachable over SSH; administration is via SSM Session Manager.
data "aws_ssm_parameter" "ubuntu_2404" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

module "ec2" {
  source = "../../modules/ec2"

  instances = {
    microservices = {
      instance_type           = var.ec2.microservices.instance_type
      subnet_id               = module.subnets.private_subnet_ids[0]
      security_group_ids      = concat([module.security_groups.security_group_ids["microservices"]], var.ec2.microservices.additional_security_group_ids)
      iam_instance_profile    = module.iam.instance_profile_names["ec2_ssm"]
      ami                     = var.ec2.microservices.ami_id
      monitoring              = true
      disable_api_termination = false

      # user_data = templatefile("${path.module}/cloud-init/microservices-host.yaml.tftpl", {
      #   environment   = var.environment
      #   region        = var.region
      #   # otlp_endpoint = var.observability.otlp_endpoint
      # })

      root_volume = {
        size       = var.ec2.microservices.volume_size
        type       = var.ec2.microservices.volume_type
        encrypted  = true
        kms_key_id = module.kms_ebs.key_arn
      }

      tags = {
        Component = "microservices-runtime"
        Role      = "application"
      }
    }

    platform = {
      instance_type           = var.ec2.platform.instance_type
      subnet_id               = module.subnets.private_subnet_ids[length(module.subnets.private_subnet_ids) > 1 ? 1 : 0]
      security_group_ids      = concat([module.security_groups.security_group_ids["platform"]], var.ec2.platform.additional_security_group_ids)
      iam_instance_profile    = module.iam.instance_profile_names["ec2_ssm"]
      ami                     = var.ec2.platform.ami_id
      monitoring              = true
      disable_api_termination = false

      # user_data = templatefile("${path.module}/cloud-init/platform-host.yaml.tftpl", {
      #   environment   = var.environment
      #   region        = var.region
      #   # otlp_endpoint = var.observability.otlp_endpoint
      # })

      root_volume = {
        size       = var.ec2.platform.volume_size
        type       = var.ec2.platform.volume_type
        encrypted  = true
        kms_key_id = module.kms_ebs.key_arn
      }

      tags = {
        Component = "observability-messaging"
        Role      = "platform"
      }
    }
    # management = {
    #   instance_type           = var.ec2.management.instance_type
    #   subnet_id               = module.subnets.private_subnet_ids[length(module.subnets.private_subnet_ids) > 1 ? 1 : 0]
    #   security_group_ids      = concat([module.security_groups.security_group_ids["management"]], var.ec2.management.additional_security_group_ids)
    #   iam_instance_profile    = module.iam.instance_profile_names["ec2_ssm"]
    #   ami                     = var.ec2.management.ami_id
    #   monitoring              = true
    #   disable_api_termination = false

    #   # user_data = templatefile("${path.module}/cloud-init/management-host.yaml.tftpl", {
    #   #   environment   = var.environment
    #   #   region        = var.region
    #   #   # otlp_endpoint = var.observability.otlp_endpoint
    #   # })

    #   root_volume = {
    #     size       = var.ec2.management.volume_size
    #     type       = var.ec2.management.volume_type
    #     encrypted  = true
    #     kms_key_id = module.kms_ebs.key_arn
    #   }

    #   tags = {
    #     Component = "observability-messaging"
    #     Role      = "management"
    #   }
    # }

  }

  tags = local.common_tags
}
