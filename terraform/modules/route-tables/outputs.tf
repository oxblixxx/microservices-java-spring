output "public_route_table_id" {
  description = "ID of the public route table, or null when not created."
  value       = try(aws_route_table.public[0].id, null)
}

output "private_route_table_ids" {
  description = "Ordered list of private route table IDs (one per private subnet)."
  value       = aws_route_table.private[*].id
}

output "management_route_table_id" {
  description = "ID of the management route table, or null when not created."
  value       = try(aws_route_table.management[0].id, null)
}

output "route_table_ids" {
  description = "All route table IDs created by the module."
  value = compact(concat(
    aws_route_table.public[*].id,
    aws_route_table.private[*].id,
    aws_route_table.management[*].id,
  ))
}

output "private_route_table_ids_by_subnet" {
  description = "Map of private subnet ID to its route table ID."
  value       = { for i, rt in aws_route_table.private : var.private_subnet_ids[i] => rt.id }
}
