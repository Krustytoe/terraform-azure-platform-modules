variable "name" {
  description = "Action group name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into (must already exist)."
  type        = string
}

variable "short_name" {
  description = "Short display name used in SMS and voice notifications (max 12 chars)."
  type        = string

  validation {
    condition     = length(var.short_name) <= 12
    error_message = "short_name must be 12 characters or fewer."
  }
}

variable "email_receivers" {
  description = "Email notification receivers."
  type = list(object({
    name    = string
    address = string
  }))
  default = []
}

variable "webhook_receivers" {
  description = <<-EOT
    Webhook receivers, e.g. PagerDuty or Opsgenie integration URLs.
    Treated as sensitive: integration URLs typically embed a routing key.
    Keyed by index in resources so URLs never appear in addresses or plan output.
  EOT
  type = list(object({
    name = string
    uri  = string
  }))
  default   = []
  sensitive = true

  validation {
    condition     = alltrue([for w in var.webhook_receivers : startswith(w.uri, "https://")])
    error_message = "All webhook URIs must use https://."
  }
}

variable "tags" {
  description = "Tags merged onto every resource."
  type        = map(string)
  default     = {}
}
