# monitor-action-group

## Requirements

Terraform >= 1.7, Azure provider >= 3.100. Run `terraform test` for offline validation (no Azure credentials required).

Azure Monitor action group for routing alerts to email and webhooks (PagerDuty, Opsgenie, etc.). Convention mirrors the SNS alerting module in `terraform-aws-platform-modules`: create one group per severity so routing stays explicit.

## Convention

| Action group | Meaning | Typical receivers |
|---|---|---|
| `<env>-warning` | Awareness; act within business hours | Email, ticketing webhook |
| `<env>-critical` | Service impact; act now | PagerDuty / on-call webhook |

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Action group name |
| `resource_group_name` | string | — | Must already exist |
| `short_name` | string | — | ≤12 chars; shown in SMS/voice |
| `email_receivers` | list(object) | `[]` | `{name, address}` pairs |
| `webhook_receivers` | list(object), sensitive | `[]` | `{name, uri}` pairs; `https://` enforced |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`action_group_id`
