output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC."
  value       = aws_internet_gateway.this.id
}

output "default_security_group_id" {
  description = "ID of the (managed) default security group, or null when unmanaged."
  value       = try(aws_default_security_group.this[0].id, null)
}

output "flow_logs_log_group_name" {
  description = "Name of the flow logs CloudWatch log group, or null when disabled."
  value       = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}

output "flow_logs_log_group_arn" {
  description = "ARN of the flow logs CloudWatch log group, or null when disabled."
  value       = try(aws_cloudwatch_log_group.flow_logs[0].arn, null)
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log, or null when disabled."
  value       = try(aws_flow_log.this[0].id, null)
}
