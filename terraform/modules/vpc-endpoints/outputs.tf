output "endpoint_ids" {
  description = "Map of logical endpoint name to VPC endpoint ID."
  value       = { for k, v in aws_vpc_endpoint.this : k => v.id }
}

output "endpoint_dns_entries" {
  description = "Map of logical endpoint name to its DNS entries (interface endpoints)."
  value       = { for k, v in aws_vpc_endpoint.this : k => v.dns_entry }
}

output "interface_endpoint_ids" {
  description = "IDs of created Interface endpoints."
  value       = { for k, v in aws_vpc_endpoint.this : k => v.id if v.vpc_endpoint_type == "Interface" }
}

output "gateway_endpoint_ids" {
  description = "IDs of created Gateway endpoints."
  value       = { for k, v in aws_vpc_endpoint.this : k => v.id if v.vpc_endpoint_type == "Gateway" }
}
