variable "name" {
  description = "User-assigned managed identity name."
  type        = string
}

variable "location" {
  description = "Azure region, e.g. \"eastus\" or \"usgovvirginia\"."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy into (must already exist)."
  type        = string
}

variable "subject_claims" {
  description = <<-EOT
    GitHub OIDC `sub` claims to trust as federated credentials. Scope as tightly as possible, e.g.
      "repo:my-org/infra:ref:refs/heads/main"
      "repo:my-org/infra:environment:prod"
      "repo:my-org/infra:pull_request"
    Org- or repo-wide wildcards ("repo:*", "repo:my-org/*") are rejected.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subject_claims) > 0
    error_message = "At least one subject claim is required."
  }

  validation {
    condition     = alltrue([for s in var.subject_claims : can(regex("^repo:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+:[^*].*$", s))])
    error_message = "Each subject must be repo:<owner>/<repo>:<qualifier>; org- or repo-wide wildcards are rejected."
  }
}

variable "role_assignments" {
  description = "RBAC role assignments to grant the managed identity."
  type = list(object({
    scope                = string
    role_definition_name = string
  }))
  default = []
}

variable "tags" {
  description = "Tags merged onto every resource."
  type        = map(string)
  default     = {}
}
