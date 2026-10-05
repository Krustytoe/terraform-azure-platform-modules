# github-oidc-role

## Requirements

Terraform >= 1.7, Azure provider >= 3.100. Run `terraform test` for offline validation (no Azure credentials required).

User-assigned managed identity with GitHub OIDC federated credentials, so GitHub Actions workflows authenticate to Azure without any client secrets or certificates in repo secrets.

## Why the guardrails

The most common OIDC misconfiguration is a trust with `sub = "repo:my-org/*"` or no `sub` at all, letting any repo in the org assume the identity. This module refuses those values:

| `subject_claims` value | Result |
|---|---|
| `repo:my-org/infra:environment:prod` | ✅ recommended: pairs with GitHub environment protection rules |
| `repo:my-org/infra:ref:refs/heads/main` | ✅ |
| `repo:my-org/infra:pull_request` | ✅ (give read-only roles) |
| `repo:my-org/*` | ❌ rejected |
| `repo:*` | ❌ rejected |

## Workflow side

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    environment: prod
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Managed identity name |
| `location` | string | — | Azure region |
| `resource_group_name` | string | — | Must already exist |
| `subject_claims` | list(string) | — | Allowed `sub` claims (validated) |
| `role_assignments` | list(object) | `[]` | `{scope, role_definition_name}` pairs |
| `tags` | map(string) | `{}` | Extra tags |

## Outputs

`identity_id`, `client_id`, `principal_id`
