terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.log_groups

  name              = each.value.name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id
  skip_destroy      = each.value.skip_destroy

  tags = merge(var.tags, each.value.tags, { Name = each.value.name })
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = var.metric_alarms

  alarm_name          = each.value.alarm_name
  alarm_description   = each.value.description
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  unit                = each.value.unit
  datapoints_to_alarm = each.value.datapoints_to_alarm
  treat_missing_data  = each.value.treat_missing_data

  dimensions = each.value.dimensions

  alarm_actions             = each.value.alarm_actions
  ok_actions                = each.value.ok_actions
  insufficient_data_actions = each.value.insufficient_data_actions

  tags = merge(var.tags, each.value.tags, { Name = each.value.alarm_name })
}

resource "aws_cloudwatch_dashboard" "this" {
  for_each = var.dashboards

  dashboard_name = each.value.name
  dashboard_body = each.value.body
}
