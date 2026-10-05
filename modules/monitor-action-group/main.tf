resource "azurerm_monitor_action_group" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  short_name          = var.short_name
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name                    = email_receiver.value.name
      email_address           = email_receiver.value.address
      use_common_alert_schema = true
    }
  }

  # Keyed by index so the (sensitive) URI never becomes part of a resource address.
  dynamic "webhook_receiver" {
    for_each = { for i, w in var.webhook_receivers : tostring(i) => w }
    content {
      name                    = webhook_receiver.value.name
      service_uri             = webhook_receiver.value.uri
      use_common_alert_schema = true
    }
  }
}
