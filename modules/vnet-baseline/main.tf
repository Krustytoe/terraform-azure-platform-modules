locals {
  # Azure auto-creates a Network Watcher named NetworkWatcher_<region> per subscription per region.
  network_watcher_name = coalesce(var.network_watcher_name, "NetworkWatcher_${var.location}")
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

resource "azurerm_network_security_group" "this" {
  for_each = var.subnets

  name                = "${var.name}-${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

# VNet flow logs (one per VNet) replace per-NSG flow logs: Azure no longer allows creating NSG flow logs
# and retires them on 2027-09-30. Requires azurerm >= 4.11 for target_resource_id.
resource "azurerm_network_watcher_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  name                 = "${var.name}-vnet-fl"
  network_watcher_name = local.network_watcher_name
  resource_group_name  = var.network_watcher_resource_group_name
  target_resource_id   = azurerm_virtual_network.this.id
  storage_account_id   = var.flow_log_storage_account_id
  enabled              = true
  version              = 2
  tags                 = var.tags

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_days
  }

  lifecycle {
    precondition {
      condition     = var.flow_log_storage_account_id != null
      error_message = "flow_log_storage_account_id is required when enable_flow_logs = true (flow logs are on by default). Pass a storage account ID or set enable_flow_logs = false."
    }
  }
}
