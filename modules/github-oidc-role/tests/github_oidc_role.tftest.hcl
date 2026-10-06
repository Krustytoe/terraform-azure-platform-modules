# Offline unit tests: `terraform test` against a mocked provider, no Azure credentials required.

mock_provider "azurerm" {}

variables {
  name                = "gha-deploy"
  location            = "usgovvirginia"
  resource_group_name = "platform-rg"
  subject_claims      = ["repo:example-org/infra:ref:refs/heads/main", "repo:example-org/infra:environment:prod"]
}

run "creates_identity_and_credentials" {
  command = plan

  assert {
    condition     = azurerm_user_assigned_identity.this.name == var.name
    error_message = "Identity name must match input."
  }

  assert {
    condition     = length(azurerm_federated_identity_credential.this) == 2
    error_message = "Expected one federated credential per subject claim."
  }
}

run "credentials_use_correct_issuer" {
  command = plan

  assert {
    condition     = alltrue([for c in azurerm_federated_identity_credential.this : c.issuer == "https://token.actions.githubusercontent.com"])
    error_message = "All credentials must use the GitHub Actions OIDC issuer."
  }

  assert {
    condition     = alltrue([for c in azurerm_federated_identity_credential.this : length(c.audience) == 1 && contains(c.audience, "api://AzureADTokenExchange")])
    error_message = "All credentials must use the AzureADTokenExchange audience."
  }
}

run "role_assignments_created" {
  command = plan

  variables {
    role_assignments = [
      {
        scope                = "/subscriptions/00000000-0000-0000-0000-000000000000"
        role_definition_name = "Contributor"
      }
    ]
  }

  assert {
    condition     = length(azurerm_role_assignment.this) == 1
    error_message = "Expected one role assignment per entry in var.role_assignments."
  }
}

run "no_role_assignments_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_role_assignment.this) == 0
    error_message = "No role assignments should be created when var.role_assignments is empty."
  }
}

run "rejects_wildcard_repo" {
  command = plan

  variables {
    subject_claims = ["repo:example-org/*"]
  }

  expect_failures = [var.subject_claims]
}

run "rejects_global_wildcard" {
  command = plan

  variables {
    subject_claims = ["repo:*"]
  }

  expect_failures = [var.subject_claims]
}

run "rejects_empty_subject_claims" {
  command = plan

  variables {
    subject_claims = []
  }

  expect_failures = [var.subject_claims]
}
