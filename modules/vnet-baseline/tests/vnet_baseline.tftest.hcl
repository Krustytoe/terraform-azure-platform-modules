# Offline unit tests: `terraform test` against a mocked provider, no Azure credentials required.

mock_provider "azurerm" {}

variables {
  name                = "unit-test"
  location            = "usgovvirginia"
  resource_group_name = "platform-rg"
  address_space       = "10.20.0.0/16"
  subnets = {
    app  = "10.20.0.0/24"
    data = "10.20.1.0/24"
  }
  enable_flow_logs = false
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

run "flow_logs_disabled_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_network_watcher_flow_log.this) == 0
    error_message = "No flow log resources should be created when enable_flow_logs = false."
  }
}

run "flow_logs_created_per_subnet_when_enabled" {
  command = plan

  variables {
    enable_flow_logs            = true
    flow_log_storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/shared-rg/providers/Microsoft.Storage/storageAccounts/flowlogssa"
  }

  assert {
    condition     = length(azurerm_network_watcher_flow_log.this) == 2
    error_message = "Expected one flow log per subnet when enabled."
  }
}

run "rejects_name_with_leading_hyphen" {
  command = plan

  variables {
    name = "-bad-name"
  }

  expect_failures = [var.name]
}
