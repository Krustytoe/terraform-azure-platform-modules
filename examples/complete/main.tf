provider "azurerm" {
  features {}
  # For Azure Government: environment = "usgovernment"
}

data "azurerm_subscription" "current" {}

# Prerequisites: resource group and shared storage account for flow logs must already exist.

module "vnet" {
  source = "../../modules/vnet-baseline"

  name                = "platform-prod"
  location            = "usgovvirginia"
  resource_group_name = "platform-rg"
  address_space       = "10.20.0.0/16"
  subnets = {
    app  = "10.20.0.0/24"
    data = "10.20.1.0/24"
    mgmt = "10.20.2.0/24"
  }
  enable_flow_logs            = true
  flow_log_storage_account_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/shared-rg/providers/Microsoft.Storage/storageAccounts/flowlogssa"
  tags                        = { env = "prod", managed-by = "terraform" }
}

module "gha_role" {
  source = "../../modules/github-oidc-role"

  name                = "gha-platform-prod"
  location            = "usgovvirginia"
  resource_group_name = "platform-rg"
  subject_claims      = ["repo:my-org/infra:environment:prod"]
  role_assignments = [
    {
      scope                = data.azurerm_subscription.current.id
      role_definition_name = "Contributor"
    }
  ]
  tags = { env = "prod", managed-by = "terraform" }
}

module "critical_alerts" {
  source = "../../modules/monitor-action-group"

  name                = "platform-prod-critical"
  resource_group_name = "platform-rg"
  short_name          = "plat-crit"
  email_receivers = [
    { name = "oncall-email", address = "oncall@example.com" }
  ]
  webhook_receivers = [
    { name = "pagerduty", uri = "https://events.pagerduty.com/integration/<routing-key>/enqueue" }
  ]
  tags = { env = "prod", managed-by = "terraform" }
}
