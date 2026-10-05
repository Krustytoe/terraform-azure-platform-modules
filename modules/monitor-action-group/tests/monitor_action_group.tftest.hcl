# Offline unit tests: `terraform test` against a mocked provider, no Azure credentials required.

mock_provider "azurerm" {}

variables {
  name                = "platform-prod-critical"
  resource_group_name = "platform-rg"
  short_name          = "plat-crit"
}

run "creates_action_group" {
  command = plan

  assert {
    condition     = azurerm_monitor_action_group.this.short_name == var.short_name
    error_message = "Short name must match input."
  }
}

run "email_receivers_created" {
  command = plan

  variables {
    email_receivers = [
      { name = "oncall-email", address = "oncall@example.com" }
    ]
  }

  assert {
    condition     = length(azurerm_monitor_action_group.this.email_receiver) == 1
    error_message = "Expected one email receiver."
  }
}

run "email_receivers_use_common_schema" {
  command = plan

  variables {
    email_receivers = [
      { name = "oncall-email", address = "oncall@example.com" }
    ]
  }

  assert {
    condition     = alltrue([for r in azurerm_monitor_action_group.this.email_receiver : r.use_common_alert_schema == true])
    error_message = "All email receivers must use the common alert schema."
  }
}

run "rejects_plain_http_webhook" {
  command = plan

  variables {
    webhook_receivers = [
      { name = "pagerduty", uri = "http://insecure.example.com/hook" }
    ]
  }

  expect_failures = [var.webhook_receivers]
}

run "rejects_short_name_over_12_chars" {
  command = plan

  variables {
    short_name = "this-is-toolong"
  }

  expect_failures = [var.short_name]
}
