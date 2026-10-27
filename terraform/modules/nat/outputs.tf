output "enabled" {
  description = "Whether NAT gateways were created."
  value       = local.gateway_count > 0
}

output "nat_gateway_ids" {
  description = "Ordered list of NAT gateway IDs."
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "Ordered list of public Elastic IP addresses used by the NAT gateways."
  value       = aws_eip.this[*].public_ip
}

output "nat_gateway_ids_by_subnet" {
  description = "Map of hosting public subnet ID to NAT gateway ID."
  value       = { for i, gw in aws_nat_gateway.this : var.public_subnet_ids[i] => gw.id }
}
