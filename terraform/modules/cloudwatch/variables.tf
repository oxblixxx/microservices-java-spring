variable "log_groups" {
  description = "Map of logical log group key to its configuration."
  type = map(object({
    name              = string
    retention_in_days = optional(number, 30)
    kms_key_id        = optional(string, null)
    skip_destroy      = optional(bool, false)
    tags              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for g in values(var.log_groups) : contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], g.retention_in_days)
    ])
    error_message = "retention_in_days must be a value supported by CloudWatch Logs (0 means never expire)."
  }
}

variable "metric_alarms" {
  description = "Map of logical alarm key to CloudWatch metric alarm configuration."
  type = map(object({
    alarm_name                = string
    comparison_operator       = string
    evaluation_periods        = number
    metric_name               = string
    namespace                 = string
    period                    = number
    statistic                 = string
    threshold                 = number
    description               = optional(string, null)
    unit                      = optional(string, null)
    datapoints_to_alarm       = optional(number, null)
    treat_missing_data        = optional(string, "missing")
    dimensions                = optional(map(string), {})
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    tags                      = optional(map(string), {})
  }))
  default = {}
}

variable "dashboards" {
  description = "Map of logical dashboard key to its configuration."
  type = map(object({
    name = string
    body = string
  }))
  default = {}
}

variable "tags" {
  description = "Common tags applied to CloudWatch resources."
  type        = map(string)
  default     = {}
}
