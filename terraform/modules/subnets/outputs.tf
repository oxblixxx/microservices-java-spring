locals {
  public_az_to_id     = { for s in aws_subnet.public : s.availability_zone => s.id }
  private_az_to_id    = { for s in aws_subnet.private : s.availability_zone => s.id }
  management_az_to_id = { for s in aws_subnet.management : s.availability_zone => s.id }

  all_subnet_ids = concat(
    aws_subnet.public[*].id,
    aws_subnet.private[*].id,
    aws_subnet.management[*].id,
  )
}

output "public_subnet_ids" {
  description = "Ordered list of public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Ordered list of private/application subnet IDs."
  value       = aws_subnet.private[*].id
}

output "management_subnet_ids" {
  description = "Ordered list of management subnet IDs."
  value       = aws_subnet.management[*].id
}

output "public_subnet_ids_by_az" {
  description = "Map of availability zone to public subnet ID."
  value       = local.public_az_to_id
}

output "private_subnet_ids_by_az" {
  description = "Map of availability zone to private subnet ID."
  value       = local.private_az_to_id
}

output "management_subnet_ids_by_az" {
  description = "Map of availability zone to management subnet ID."
  value       = local.management_az_to_id
}

output "all_subnet_ids" {
  description = "All subnet IDs created by the module."
  value       = local.all_subnet_ids
}
