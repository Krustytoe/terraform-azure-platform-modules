# vnet-baseline

## Requirements

Terraform >= 1.7, Azure provider >= 4.11 (for VNet flow logs). Run `terraform test` for offline validation (no Azure credentials required).

Multi-subnet VNet with per-subnet NSGs and VNet flow logs. Works in Azure commercial and Azure Government — set `environment = "usgovernment"` in the provider block.

## Layout

With `address_space = "10.20.0.0/16"` and the default two-subnet config:

| Subnet | CIDR | NSG |
|---|---|---|
| app | 10.20.0.0/24 | `<name>-app-nsg` |
| data | 10.20.1.0/24 | `<name>-data-nsg` |

Every subnet gets its own NSG associated on creation. Flow logs are on by default as a single **VNet flow log** (version 2) covering every subnet, and require an existing Standard general-purpose v2 storage account in the same region, typically a shared logging account. Plan fails with a clear error if flow logs are on and no storage account is given.

> **Why VNet flow logs:** Azure no longer allows creating NSG flow logs and retires them on 2027-09-30 ([announcement](https://learn.microsoft.com/en-us/azure/network-watcher/nsg-flow-logs-overview)). NSG flow logs also don't support newer VM sizes (D/E/F v6 series); Microsoft recommends VNet flow logs for those.

### Upgrading from v0.1.x

The per-NSG flow logs (`azurerm_network_watcher_flow_log.this["<subnet>"]`) are destroyed and replaced by one VNet flow log (`azurerm_network_watcher_flow_log.this[0]`). Records already written to storage are kept under their retention policy. Expect a short gap in flow data during the apply. Upgrade the provider to azurerm >= 4.11 first.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix (3-24 chars, `[a-z0-9-]`) |
| `location` | string | — | Azure region |
| `resource_group_name` | string | — | Must already exist |
| `address_space` | string | — | VNet IPv4 CIDR |
| `subnets` | map(string) | app + data | Subnet name → address prefix |
| `enable_flow_logs` | bool | `true` | VNet flow log to storage account |
| `flow_log_storage_account_id` | string | `null` | Required when flow logs enabled; Standard GPv2, same region |
| `flow_log_retention_days` | number | `90` | Retention days (0 = forever) |
| `network_watcher_name` | string | `NetworkWatcher_<location>` | Override if non-default |
| `network_watcher_resource_group_name` | string | `NetworkWatcherRG` | Override if non-default |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`vnet_id`, `vnet_name`, `subnet_ids`, `nsg_ids`, `flow_log_id`
