# vnet-baseline

## Requirements

Terraform >= 1.7, Azure provider >= 3.100. Run `terraform test` for offline validation (no Azure credentials required).

Multi-subnet VNet with per-subnet NSGs and optional NSG flow logs. Works in Azure commercial and Azure Government — set `environment = "usgovernment"` in the provider block.

## Layout

With `address_space = "10.20.0.0/16"` and the default two-subnet config:

| Subnet | CIDR | NSG |
|---|---|---|
| app | 10.20.0.0/24 | `<name>-app-nsg` |
| data | 10.20.1.0/24 | `<name>-data-nsg` |

Every subnet gets its own NSG associated on creation. Flow logs are per-NSG (version 2) and require an existing storage account — typically a shared logging account is passed in.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix (3-24 chars, `[a-z0-9-]`) |
| `location` | string | — | Azure region |
| `resource_group_name` | string | — | Must already exist |
| `address_space` | string | — | VNet IPv4 CIDR |
| `subnets` | map(string) | app + data | Subnet name → address prefix |
| `enable_flow_logs` | bool | `true` | NSG flow logs to storage account |
| `flow_log_storage_account_id` | string | `null` | Required when flow logs enabled |
| `flow_log_retention_days` | number | `90` | Retention days (0 = forever) |
| `network_watcher_name` | string | `NetworkWatcher_<location>` | Override if non-default |
| `network_watcher_resource_group_name` | string | `NetworkWatcherRG` | Override if non-default |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`vnet_id`, `vnet_name`, `subnet_ids`, `nsg_ids`
