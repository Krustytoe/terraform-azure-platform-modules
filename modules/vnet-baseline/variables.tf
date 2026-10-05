variable "name" {
  description = "Name prefix for all resources (3-24 chars, lowercase alphanumeric and hyphens)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,22}[a-z0-9]$", var.name))
    error_message = "name must be 3-24 chars, lowercase alphanumeric and hyphens, not starting or ending with a hyphen."
  }
}

variable "location" {
  description = "Azure region, e.g. \"eastus\" or \"usgovvirginia\"."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into (must already exist)."
  type        = string
}

variable "address_space" {
  description = "VNet IPv4 CIDR, e.g. \"10.20.0.0/16\"."
  type        = string
}

variable "subnets" {
  description = "Map of subnet name to address prefix."
  type        = map(string)
  default = {
    app  = "10.0.0.0/24"
    data = "10.0.1.0/24"
  }
}

variable "enable_flow_logs" {
  description = "Enable NSG flow logs to a storage account."
  type        = bool
  default     = true
}

variable "flow_log_storage_account_id" {
  description = "Storage account resource ID for NSG flow logs. Required when enable_flow_logs = true."
  type        = string
  default     = null
}

variable "flow_log_retention_days" {
  description = "Days to retain flow logs in the storage account (0 = forever)."
  type        = number
  default     = 90
}

variable "network_watcher_name" {
  description = "Network Watcher name in this region. Azure creates one automatically per subscription per region; override if yours has a non-default name."
  type        = string
  default     = null
}

variable "network_watcher_resource_group_name" {
  description = "Resource group that owns the Network Watcher. Defaults to 'NetworkWatcherRG'."
  type        = string
  default     = "NetworkWatcherRG"
}

variable "tags" {
  description = "Tags merged onto every resource."
  type        = map(string)
  default     = {}
}
