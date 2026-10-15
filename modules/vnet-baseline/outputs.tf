output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "nsg_ids" {
  description = "Map of subnet name to NSG resource ID."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "flow_log_id" {
  description = "Resource ID of the VNet flow log, or null when flow logs are disabled."
  value       = one(azurerm_network_watcher_flow_log.this[*].id)
}
