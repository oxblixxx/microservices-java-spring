output "log_group_names" {
  description = "Map of logical log group key to log group name."
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.name }
}

output "log_group_arns" {
  description = "Map of logical log group key to log group ARN."
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.arn }
}

output "metric_alarm_arns" {
  description = "Map of logical alarm key to alarm ARN."
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}

output "dashboard_names" {
  description = "Map of logical dashboard key to dashboard name."
  value       = { for k, v in aws_cloudwatch_dashboard.this : k => v.dashboard_name }
}
