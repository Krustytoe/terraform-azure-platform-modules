resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# One federated credential per subject claim; keyed by index so claim values never become
# resource addresses (avoids logging sensitive org/repo names in broad audit trails).
resource "azurerm_federated_identity_credential" "this" {
  for_each = { for i, s in var.subject_claims : tostring(i) => s }

  name                = "${var.name}-${each.key}"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.this.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = each.value
}

resource "azurerm_role_assignment" "this" {
  for_each = { for ra in var.role_assignments : "${ra.scope}::${ra.role_definition_name}" => ra }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}
