

<!-- Source: .ruler/AGENTS.md -->

# terraform-azure-platform-modules

Small, opinionated Terraform modules for a secure Azure platform baseline. Every module must work unchanged in Azure commercial and Azure Government; the caller selects the cloud via the `azurerm` provider (`environment = "usgovernment"`).

## Layout

- `modules/<name>/` — one module per directory: `vnet-baseline`, `github-oidc-role`, `monitor-action-group`.
  - `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, `.terraform.lock.hcl`
  - `tests/<name>.tftest.hcl` — offline unit tests against a mocked `azurerm` provider
- `examples/complete/main.tf` — all modules wired together (not in the CI matrix).
- `.tflint.hcl` — repo-root tflint config (terraform `recommended` preset + `tflint-ruleset-azurerm`).
- `.github/workflows/` — `terraform.yml` (fmt/validate/test + tflint), `security.yml` (Trivy config scan), `release-please.yml`, `scorecard.yml` (OpenSSF Scorecard), `dependabot-auto-merge.yml`, `ruler.yml`.
- `release-please-config.json`, `.release-please-manifest.json`, `CHANGELOG.md` — managed by release-please; do not hand-edit versions or the changelog.
- `.ruler/` — source of truth for agent instructions.

## Commands

Requires Terraform >= 1.7 (CI uses `~1.10`) and tflint (CI pins v0.64.0). No cloud credentials are needed; every test uses a mocked provider.

```bash
# from repo root
terraform fmt -check -recursive

# for each module you touched
cd modules/<module>
terraform init -backend=false
terraform validate
terraform test          # only where tests/*.tftest.hcl exists (all modules today)
cd -

# lint, from repo root
tflint --init
tflint --recursive
```

- CI runs init/validate/test for `vnet-baseline`, `github-oidc-role`, and `monitor-action-group`. Add new modules to the matrix in `.github/workflows/terraform.yml`.
- `security.yml` runs a Trivy config scan (`severity: HIGH,CRITICAL`) via a reusable workflow; there is no local wrapper in this repo.
- `.terraform.lock.hcl` files are committed per module and example; keep them in sync when provider constraints change.

## Module conventions

- Keep the file split: `main.tf` / `variables.tf` / `outputs.tf` / `versions.tf` / `README.md` / `tests/`.
- `versions.tf`: `required_version = ">= 1.7"` and a bounded `hashicorp/azurerm` constraint that floors what the module needs and caps the next major (`">= 3.100, < 5.0"`; `vnet-baseline` needs `">= 4.11, < 5.0"` for VNet flow logs).
- Cloud-agnostic: never hard-code `AzureCloud` endpoints, cloud names, or regions in modules. Location and resource group are inputs.
- Secure by default: any input that weakens a control (logging off, public access on, encryption off) defaults to the secure value and says so in its description. Example: VNet flow logs are on by default and the plan fails without a storage account.
- Every subnet gets its own NSG, always associated; no code path creates an unprotected subnet.
- Every variable and output has a `description` and every variable a `type`. Use `validation` blocks to reject bad input at plan time (e.g. wildcard OIDC `sub` claims, non-`https://` webhooks).
- Mark secret-bearing inputs `sensitive = true` and key resources/dynamic blocks from them by index, so values (webhook URIs, org/repo names) never appear in resource addresses or plan output.
- Tagging: every module takes `variable "tags"` (`map(string)`, default `{}`, "Tags merged onto every resource.") and sets `tags = var.tags` on every taggable resource.
- Every module change ships with a test in `tests/*.tftest.hcl`, including the negative case (`expect_failures`) for each `validation` block. Prefer `command = plan`; use `command = apply` only against the mock when a value is unknown at plan time. Mocked IDs must be well-formed ARM IDs with all-zero GUIDs.
- When an interface changes, update the module `README.md` inputs/outputs and the root `README.md` module table.

## Guardrails

- Never run `terraform apply`, `terraform destroy`, or anything that touches a real Azure subscription or tenant without explicit human approval. Prefer `terraform test` against the mock, `validate`, and plan/diff output.
- No secrets in code, examples, fixtures, logs, or output: no tokens, keys, webhook URLs, subscription/tenant IDs, or internal hostnames. Use obvious placeholders; never commit `*.tfvars` or state.
- Pin third-party GitHub Actions to a full commit SHA with the version as a trailing comment (`uses: org/action@<sha> # v1.2.3`).
- PR titles must be Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`, `chore:`); mark breaking interface changes with `!`. PRs are squash-merged and the title drives release-please.
- Keep changes focused: one concern per PR.
- Report security issues privately per `SECURITY.md`, never in a public issue.
- Generated agent files (`AGENTS.md`, `CLAUDE.md`, `.gemini/settings.json` at repo root) are produced by Ruler from `.ruler/`. Edit `.ruler/AGENTS.md`, then run `npx @intellectronica/ruler@0.3.46 apply`. Never hand-edit the generated files; the `ruler` CI workflow fails on drift.

## Definition of done

- `terraform fmt -check -recursive` passes.
- `terraform init -backend=false`, `terraform validate`, and `terraform test` pass in every touched module.
- `tflint --init && tflint --recursive` passes from the repo root.
- New or changed behavior has a test, including negative cases for validations.
- Module and root READMEs reflect any input/output changes.
- No secrets, real IDs, or hard-coded cloud endpoints/regions introduced in modules.
- If `.ruler/` changed, Ruler was re-run and the generated files are included.
