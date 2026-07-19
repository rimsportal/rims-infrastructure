# AGENTS.md — RIMS Infrastructure Conventions

Conventions for AI-assisted edits to this repository. Preserve them in all changes.

## Layout

```text
rims/                            # organization root (Terraform Cloud org name)
  .github/workflows/             # terraform-plan.yml, terraform-apply.yml,
                                 # terraform-destroy.yml, pre-checks.yml
  .gitignore
  docs/                          # architecture, operational, onboarding docs
  foundation/                    # ALL Terraform configuration lives here
    AGENTS.md
    README.md
    deployments/
      modules/<module>/          # reusable modules: main.tf, variables.tf, outputs.tf (all three required)
      projects/<project>/<env>/  # environment roots: backend.tf, locals.tf, main.tf,
                                 # outputs.tf, terraform.tfvars, variables.tf (exactly these six)
  scripts/                       # repeatable non-secret automation
```

Current: project `core`, environments `dev`, `qa`, `preprod`, `prod`.

## Rules

- Terraform `required_version` is `>= 1.5.0`; `hashicorp/azurerm` pinned to `~> 3.100`.
- State lives in Terraform Cloud, organization `rims`. Workspace naming: `rims-<project>-<env>-HCP`.
- Resource group naming: `<brand_short>-<project_short>-<env_short>-<location_short>-rg`
  (e.g. `rims-core-dev-cin-rg`). Derived in `locals.tf`; never hardcode.
- Standard tags on every resource: `Brand`, `Environment`, `Project`, `ManagedBy` (from `locals.tags`).
- `terraform.tfvars` holds non-secret values only. Secrets (passwords, client secrets, access keys,
  tokens, connection strings) go in Terraform Cloud workspace variables or GitHub secrets, marked sensitive.
- Every environment root must include `data "azurerm_client_config" "current" {}`.
- New reusable modules go in `foundation/deployments/modules/` with `main.tf`, `variables.tf`, `outputs.tf`.
  Every input needs a description and type; expose identifiers downstream modules need.
- Do not modify unrelated projects or environments when adding new ones.
- When adding a project or environment, update workflow input descriptions where choices are enumerated.
- All workflow Terraform commands run in the selected directory under `foundation/deployments/projects`.
- Run `terraform fmt -recursive` from `foundation/` before committing.

## Variables required in every environment root

`location`, `brand`, `environment`, `project`, `managed_by` (default `Terraform`),
`brand_short_name`, `environment_short_name`, `project_short_name`, `location_short_name`.
