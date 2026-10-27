module "vpc" {
  source = "../../modules/vpc"

  name                          = local.name_prefix
  cidr_block                    = var.network.cidr
  enable_dns_support            = true
  enable_dns_hostnames          = true
  manage_default_security_group = true
  enable_flow_logs              = var.network.enable_flow_logs
  flow_logs_traffic_type        = "ALL"
  flow_logs_retention_days      = var.network.flow_logs_retention_days
  #flow_logs_kms_key_arn         = module.kms_logs.key_arn

  tags = local.common_tags
}

module "subnets" {
  source = "../../modules/subnets"

  name                    = local.name_prefix
  vpc_id                  = module.vpc.vpc_id
  azs                     = var.network.azs
  public_subnets          = var.network.public_subnets
  private_subnets         = var.network.private_subnets
  management_subnets      = var.network.management_subnets
  map_public_ip_on_launch = var.network.map_public_ip_on_launch

  tags = local.common_tags
}

# module "nat" {
#   source = "../../modules/nat"

#   name              = local.name_prefix
#   enabled           = var.nat.enabled
#   public_subnet_ids = module.subnets.public_subnet_ids
#   per_az            = var.nat.per_az

#   tags = local.common_tags
# }

module "route_tables" {
  source = "../../modules/route-tables"

  name                     = local.name_prefix
  vpc_id                   = module.vpc.vpc_id
  internet_gateway_id      = module.vpc.internet_gateway_id
  public_subnet_ids        = module.subnets.public_subnet_ids
  private_subnet_ids       = module.subnets.private_subnet_ids
#  management_subnet_ids    = module.subnets.management_subnet_ids
#  nat_gateway_ids          = module.nat.nat_gateway_ids
  public_default_route     = "igw"
  private_default_route    = var.nat.enabled ? "nat" : "none"
  management_default_route = "none"

  tags = local.common_tags
}

module "vpc_endpoints" {
  source = "../../modules/vpc-endpoints"

  name               = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  region             = var.region
  subnet_ids         = module.subnets.private_subnet_ids
  security_group_ids = [module.security_groups.security_group_ids["vpc_endpoints"]]
  route_table_ids    = module.route_tables.route_table_ids

  interface_services = var.vpc_endpoints.interface_services
  gateway_services   = var.vpc_endpoints.gateway_services
#  custom_endpoints   = var.vpc_endpoints.custom

  tags = local.common_tags
}
