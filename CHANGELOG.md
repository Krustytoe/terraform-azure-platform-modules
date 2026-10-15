# Changelog

## [0.2.0](https://github.com/Krustytoe/terraform-azure-platform-modules/compare/v0.1.1...v0.2.0) (2026-10-15)


### ⚠ BREAKING CHANGES

* **vnet-baseline:** vnet-baseline requires azurerm >= 4.11. Existing per-NSG flow logs are destroyed and replaced by a single VNet flow log.

### Bug Fixes

* **vnet-baseline:** replace retired NSG flow logs with VNet flow logs ([#7](https://github.com/Krustytoe/terraform-azure-platform-modules/issues/7)) ([839c3a6](https://github.com/Krustytoe/terraform-azure-platform-modules/commit/839c3a696c2015690d2591c69495d44b32ee2e9e))

## [0.1.1](https://github.com/Krustytoe/terraform-azure-platform-modules/compare/v0.1.0...v0.1.1) (2026-10-06)


### Bug Fixes

* terraform test crash and tflint findings ([#1](https://github.com/Krustytoe/terraform-azure-platform-modules/issues/1)) ([ebdaef9](https://github.com/Krustytoe/terraform-azure-platform-modules/commit/ebdaef946d569325af4eb98c2e8e735fdb5ec57e))
