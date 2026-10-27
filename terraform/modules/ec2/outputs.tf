output "instance_ids" {
  description = "Map of logical instance key to instance ID."
  value       = { for k, v in aws_instance.this : k => v.id }
}

output "instance_arns" {
  description = "Map of logical instance key to instance ARN."
  value       = { for k, v in aws_instance.this : k => v.arn }
}

output "private_ips" {
  description = "Map of logical instance key to its private IP address."
  value       = { for k, v in aws_instance.this : k => v.private_ip }
}

output "public_ips" {
  description = "Map of logical instance key to its public IP address (empty for private-only instances)."
  value       = { for k, v in aws_instance.this : k => v.public_ip }
}

output "availability_zones" {
  description = "Map of logical instance key to the availability zone it runs in."
  value       = { for k, v in aws_instance.this : k => v.availability_zone }
}

output "primary_network_interface_ids" {
  description = "Map of logical instance key to its primary network interface ID."
  value       = { for k, v in aws_instance.this : k => v.primary_network_interface_id }
}

output "instance_state" {
  description = "Map of logical instance key to its current state."
  value       = { for k, v in aws_instance.this : k => v.instance_state }
}
