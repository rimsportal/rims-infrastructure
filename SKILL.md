---
name: terraform-scaffold
description: Create and extend standardized Azure Terraform repositories. Use when asked to create Terraform infrastructure from scratch, scaffold a project or environment, add a Terraform project, or apply the prescribed module and environment file layout.
---

# Terraform Scaffold

Create Azure Terraform baselines that use Terraform Cloud and the repository conventions below. Preserve existing files and ask only for details that cannot be inferred.

## Workflows

### Create a repository from scratch

Ask for these inputs before writing files:

1. Terraform Cloud organization name.
2. Brand name and short name.
3. Project name and short name.
4. Azure region and location short name.
5. Environments, including their full and short names (for example, Development/dev and Production/prod).

Create an organization directory named exactly after the supplied Terraform Cloud organization. Inside it, always create `.github/workflows`, `docs`, `foundation`, and `scripts`. Place all Terraform configuration under `foundation`:

```text
<organization>/
  .github/workflows/
    terraform-plan.yml
    terraform-apply.yml
    terraform-destroy.yml
    pre-checks.yml
  .gitignore
  docs/
    README.md
  foundation/
    AGENTS.md
    README.md
    deployments/
      modules/resource-group/
        main.tf
        variables.tf
        outputs.tf
      projects/<project>/<environment>/
        backend.tf
        locals.tf
        main.tf
        outputs.tf
        terraform.tfvars
        variables.tf
  scripts/
    README.md
```

Use `docs` for architecture, operational, and onboarding documentation. Use `scripts` for repeatable non-secret automation. Never store credentials, tokens, or access keys in any generated directory.

### Add a project

Ask for the project name, short name, target environments, and any missing organization or location details. Create `foundation/deployments/projects/<project>/<environment>/` for every requested environment. Do not modify unrelated projects. Update workflow input descriptions when project choices are explicitly enumerated.

### Add an environment

Ask for the environment full and short name, then create all six required environment files in `foundation/deployments/projects/<project>/<environment>/`. Use a distinct Terraform Cloud workspace. Update workflow input descriptions when environment choices are explicitly enumerated.

## Required Terraform content

### Modules

Every reusable module must contain `main.tf`, `variables.tf`, and `outputs.tf`. Give inputs a description and type; expose identifiers that downstream modules need.

### Environment roots

Every environment must contain exactly `backend.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `terraform.tfvars`, and `variables.tf`.

`backend.tf` must set Terraform `required_version` to `>= 1.5.0`, pin `hashicorp/azurerm` to `~> 3.100`, configure Terraform Cloud with the supplied organization, and configure the AzureRM provider with `features {}`. Workspace naming defaults to `<brand>-<project>-<environment>-HCP` unless the user gives another convention.

`locals.tf` must derive a resource-group name as `<brand_short>-<project_short>-<environment_short>-<location_short>-rg` and define tags for `Brand`, `Environment`, `Project`, and `ManagedBy`.

`main.tf` must include `data "azurerm_client_config" "current" {}` and call the resource-group module using:

```hcl
source              = "../../../modules/resource-group"
resource_group_name = local.resource_group_name
location            = var.location
tags                = local.tags
```

`variables.tf` must define: `location`, `brand`, `environment`, `project`, `managed_by` (default `Terraform`), `brand_short_name`, `environment_short_name`, `project_short_name`, and `location_short_name`.

`terraform.tfvars` may contain non-secret values only. Never write passwords, client secrets, access keys, or tokens to it; use Terraform Cloud workspace variables for secrets.

## GitHub Actions

Create the four workflow files below under the organization root so GitHub Actions discovers them. Every Terraform command must use the selected environment directory under `foundation/deployments/projects`. Set `TF_TOKEN_app_terraform_io`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, and `ARM_TENANT_ID` from GitHub secrets; never add their values to repository files. Configure protected GitHub environments before using apply or destroy workflows.

### `terraform-plan.yml`

Create a pull-request plan workflow plus a manual dispatch for a selected project and environment. Use this baseline, replacing `<project>` and `<environment>` with the scaffolded project/environment defaults:

```yaml
name: Terraform Plan

on:
  pull_request:
    paths:
      - "foundation/**"
      - ".github/workflows/terraform-plan.yml"
  workflow_dispatch:
    inputs:
      project:
        description: "Project directory name"
        required: true
        default: "<project>"
        type: string
      environment:
        description: "Environment directory name"
        required: true
        default: "<environment>"
        type: string

permissions:
  contents: read

jobs:
  plan:
    runs-on: ubuntu-latest
    env:
      TF_IN_AUTOMATION: "true"
      TF_TOKEN_app_terraform_io: ${{ secrets.TF_TOKEN_APP_TERRAFORM_IO }}
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Terraform init, validate, and plan
        working-directory: foundation/deployments/projects/${{ inputs.project || '<project>' }}/${{ inputs.environment || '<environment>' }}
        run: |
          terraform init -input=false
          terraform validate
          terraform plan -input=false
```

### `terraform-apply.yml`

Create a manual-only apply workflow. It must target a single project and environment and bind the job to the selected protected GitHub environment:

```yaml
name: Terraform Apply

on:
  workflow_dispatch:
    inputs:
      project:
        description: "Project directory name"
        required: true
        default: "<project>"
        type: string
      environment:
        description: "Environment directory name"
        required: true
        default: "<environment>"
        type: string

permissions:
  contents: read

jobs:
  apply:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    concurrency: terraform-${{ inputs.project }}-${{ inputs.environment }}
    env:
      TF_IN_AUTOMATION: "true"
      TF_TOKEN_app_terraform_io: ${{ secrets.TF_TOKEN_APP_TERRAFORM_IO }}
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Terraform init, validate, plan, and apply
        working-directory: foundation/deployments/projects/${{ inputs.project }}/${{ inputs.environment }}
        run: |
          terraform init -input=false
          terraform validate
          terraform plan -input=false -out=tfplan
          terraform apply -input=false -auto-approve tfplan
```

### `terraform-destroy.yml`

Create a manual-only destroy workflow. It must accept `all` or a specific project name and environment name. The default must be `all`; the job must use a protected `destroy` GitHub environment. It must resolve selected directories before destruction and fail if none are found:

```yaml
name: Terraform Destroy

on:
  workflow_dispatch:
    inputs:
      project:
        description: "Project directory name, or all"
        required: true
        default: "all"
        type: string
      environment:
        description: "Environment directory name, or all"
        required: true
        default: "all"
        type: string

permissions:
  contents: read

jobs:
  destroy:
    runs-on: ubuntu-latest
    environment: destroy
    concurrency: terraform-destroy
    env:
      TF_IN_AUTOMATION: "true"
      TF_TOKEN_app_terraform_io: ${{ secrets.TF_TOKEN_APP_TERRAFORM_IO }}
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Destroy selected infrastructure
        shell: bash
        env:
          PROJECT: ${{ inputs.project }}
          ENVIRONMENT: ${{ inputs.environment }}
        run: |
          set -euo pipefail
          root="foundation/deployments/projects"
          mapfile -t projects < <(find "$root" -mindepth 1 -maxdepth 1 -type d | sort)
          targets=()
          for project_dir in "${projects[@]}"; do
            project_name="$(basename "$project_dir")"
            [[ "$PROJECT" == "all" || "$PROJECT" == "$project_name" ]] || continue
            while IFS= read -r environment_dir; do
              environment_name="$(basename "$environment_dir")"
              [[ "$ENVIRONMENT" == "all" || "$ENVIRONMENT" == "$environment_name" ]] || continue
              targets+=("$environment_dir")
            done < <(find "$project_dir" -mindepth 1 -maxdepth 1 -type d | sort)
          done
          [[ ${#targets[@]} -gt 0 ]] || { echo "No matching Terraform environments found."; exit 1; }
          for target in "${targets[@]}"; do
            echo "Destroying $target"
            terraform -chdir="$target" init -input=false
            terraform -chdir="$target" destroy -input=false -auto-approve
          done
```

### `pre-checks.yml`

Create a pull-request and push pre-check workflow covering Terraform formatting, TFLint, and KICS. Use this baseline:

```yaml
name: Terraform Pre-checks

on:
  pull_request:
    paths:
      - "foundation/**"
      - ".github/workflows/pre-checks.yml"
  push:
    branches: [main]
    paths:
      - "foundation/**"
      - ".github/workflows/pre-checks.yml"

permissions:
  contents: read

jobs:
  fmt-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Check Terraform formatting
        run: terraform -chdir=foundation fmt -check -recursive

  tflint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: terraform-linters/setup-tflint@v4
      - name: Initialize and run TFLint
        run: |
          tflint --init
          tflint --recursive foundation

  kics-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run KICS scan
        uses: checkmarx/kics-github-action@v2
        with:
          path: foundation
          output_path: results
          output_formats: sarif
```

## Git ignore rules

Create the organization-root `.gitignore` with exactly these baseline entries. Keep `**/.terraform/*` even though `.terraform/` is ignored, so nested Terraform working directories remain explicitly covered:

```gitignore
# Terraform
.terraform/
*.tfstate
*.tfstate.*
crash.log


# Azure
.azure/

# VS Code
.vscode/

# OS files
.DS_Store
Thumbs.db

# Already ignored — correct
**/.terraform/*
```

## Repository guidance

Create or update `foundation/AGENTS.md` with these conventions so later AI-assisted edits preserve them. Create `foundation/README.md` covering the Terraform structure, Terraform Cloud setup, standard `init`/`fmt`/`validate`/`plan`/`apply` commands, and how to add projects, modules, and environments. Create short README files in `docs` and `scripts` that describe their intended contents. Document the required GitHub secrets and protected environments in `docs` without exposing values.

Run `terraform fmt -recursive` from the `foundation` directory and run `terraform validate` for each affected environment when tooling and configuration permit. State clearly if validation is not possible because credentials, provider access, or Terraform Cloud settings are unavailable.