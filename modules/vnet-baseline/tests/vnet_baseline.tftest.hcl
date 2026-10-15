# Offline unit tests: `terraform test` against a mocked provider, no Azure credentials required.

# Mocked IDs must be well-formed ARM IDs: azurerm parses them when one resource references another.
mock_provider "azurerm" {
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform-rg/providers/Microsoft.Network/virtualNetworks/unit-test"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform-rg/providers/Microsoft.Network/virtualNetworks/unit-test/subnets/app"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform-rg/providers/Microsoft.Network/networkSecurityGroups/unit-test-app-nsg"
    }
  }
}

# Flow logs are left at their default (enabled), so every run exercises the default path.
variables {
  name                        = "unit-test"
  location                    = "usgovvirginia"
  resource_group_name         = "platform-rg"
  address_space               = "10.20.0.0/16"
  flow_log_storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/shared-rg/providers/Microsoft.Storage/storageAccounts/flowlogssa"
  subnets = {
    app  = "10.20.0.0/24"
    data = "10.20.1.0/24"
  }
}

run "creates_vnet_subnets_and_nsgs" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this) == 2
    error_message = "Expected one subnet per entry in var.subnets."
  }

  assert {
    condition     = length(azurerm_network_security_group.this) == 2
    error_message = "Expected one NSG per subnet."
  }

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == 2
    error_message = "Every subnet must be associated with an NSG."
  }
}

# apply (against the mock) so resource IDs are known and the flow log target can be compared.
run "flow_logs_on_by_default_and_target_the_vnet" {
  command = apply

  assert {
    condition     = length(azurerm_network_watcher_flow_log.this) == 1
    error_message = "Expected a single VNet flow log by default."
  }

  assert {
    condition     = azurerm_network_watcher_flow_log.this[0].target_resource_id == azurerm_virtual_network.this.id
    error_message = "Flow log must target the VNet (NSG flow logs can no longer be created)."
  }

  assert {
    condition     = output.flow_log_id == azurerm_network_watcher_flow_log.this[0].id
    error_message = "flow_log_id output should expose the flow log ID."
  }
}

run "flow_logs_can_be_disabled" {
  command = plan

  variables {
    enable_flow_logs            = false
    flow_log_storage_account_id = null
  }

  assert {
    condition     = length(azurerm_network_watcher_flow_log.this) == 0
    error_message = "No flow log resources should be created when enable_flow_logs = false."
  }
}

run "flow_logs_require_storage_account" {
  command = plan

  variables {
    flow_log_storage_account_id = null
  }

  expect_failures = [azurerm_network_watcher_flow_log.this]
}

run "rejects_name_with_leading_hyphen" {
  command = plan

  variables {
    name = "-bad-name"
  }

  expect_failures = [var.name]
}
