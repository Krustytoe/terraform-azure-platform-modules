# terraform-azure-platform-modules

Small, opinionated Terraform modules for a secure Azure platform baseline. Works **unchanged in both Azure commercial and Azure Government** by letting the caller configure the `azurerm` provider with `environment = "usgovernment"`.

| Module | What it does | Key defaults |
|---|---|---|
| [`vnet-baseline`](modules/vnet-baseline) | Multi-subnet VNet with per-subnet NSGs and flow logs | One NSG per subnet, all associated; flow logs on by default (version 2, 90d retention) |
| [`github-oidc-role`](modules/github-oidc-role) | User-assigned managed identity with federated credentials for GitHub Actions (no client secrets) | Rejects wildcard `sub` claims like `repo:*` / `repo:org/*`; supports multiple claims per identity |
| [`monitor-action-group`](modules/monitor-action-group) | Azure Monitor action group for email and webhook notifications | Webhook URIs enforced `https://`; treated as sensitive — URLs never appear in resource addresses |

## Usage

```hcl
provider "azurerm" {
  features {}
  # For Azure Government: environment = "usgovernment"
}

module "vnet" {
  source = "git::https://github.com/Krustytoe/terraform-azure-platform-modules.git//modules/vnet-baseline?ref=v0.1.0"

  name                = "platform-prod"
  location            = "usgovvirginia"
  resource_group_name = "platform-rg"
  address_space       = "10.20.0.0/16"
  subnets = {
    app  = "10.20.0.0/24"
    data = "10.20.1.0/24"
  }
}
```

See [`examples/complete`](examples/complete) for a full working example covering all three modules.

## Requirements

Terraform >= 1.7, Azure provider >= 3.100. Run `terraform test` inside any module directory for offline validation — no Azure credentials required.

## Testing

```bash
cd modules/<module>
terraform test
```

All tests use `mock_provider "azurerm"` so they run anywhere Terraform does.

## License

MIT
