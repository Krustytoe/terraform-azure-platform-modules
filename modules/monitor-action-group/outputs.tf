output "action_group_id" {
  description = "Resource ID of the action group — pass to azurerm_monitor_metric_alert action blocks."
  value       = azurerm_monitor_action_group.this.id
}
