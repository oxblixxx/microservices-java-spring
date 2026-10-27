variable "security_groups" {
  description = "Map of logical security group key to its definition. Ingress/egress rules may reference other groups in this map by key, allowing least-privilege group-to-group rules."
  type = map(object({
    name        = string
    description = optional(string, "")
    vpc_id      = string
    tags        = optional(map(string), {})

    ingress = optional(list(object({
      description               = optional(string, "")
      from_port                 = number
      to_port                   = number
      protocol                  = string
      cidr_blocks               = optional(list(string), [])
      ipv6_cidr_blocks          = optional(list(string), [])
      prefix_list_ids           = optional(list(string), [])
      self                      = optional(bool, false)
      source_security_group_key = optional(string, null)
      source_security_group_id  = optional(string, null)
    })), [])

    egress = optional(list(object({
      description                    = optional(string, "")
      from_port                      = number
      to_port                        = number
      protocol                       = string
      cidr_blocks                    = optional(list(string), [])
      ipv6_cidr_blocks               = optional(list(string), [])
      prefix_list_ids                = optional(list(string), [])
      self                           = optional(bool, false)
      destination_security_group_key = optional(string, null)
      destination_security_group_id  = optional(string, null)
    })), [])
  }))

  validation {
    condition = alltrue([
      for sg in values(var.security_groups) : alltrue([
        for r in concat(sg.ingress, sg.egress) : contains(["tcp", "udp", "icmp", "icmpv6", "-1"], r.protocol)
      ])
    ])
    error_message = "Security group rule protocol must be one of tcp, udp, icmp, icmpv6 or -1."
  }
}

variable "tags" {
  description = "Common tags applied to all security groups in the module."
  type        = map(string)
  default     = {}
}
