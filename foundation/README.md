# RIMS Infrastructure — Foundation

Azure infrastructure for RIMS (Retail Inspection Management System), managed with Terraform and Terraform Cloud.

## Structure

```text
foundation/
  deployments/
    modules/
      resource-group/          # reusable resource-group module
    projects/
      core/
        dev/                   # Development
        qa/                    # QA
        preprod/               # PreProduction
        prod/                  # Production
```

Each environment root contains exactly: `backend.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `terraform.tfvars`, `variables.tf`.

## Terraform Cloud setup

1. Create org `rims` (or update `backend.tf` if different) at https://app.terraform.io.
2. Create workspaces: `rims-core-dev-HCP`, `rims-core-qa-HCP`, `rims-core-preprod-HCP`, `rims-core-prod-HCP` (CLI-driven workflow).
3. In each workspace set Azure credentials as sensitive environment variables:
   `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`.
4. `terraform login` locally to authenticate the CLI.

## Usage

From an environment directory, e.g. `deployments/projects/core/dev`:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

CI/CD: pull requests trigger pre-checks (fmt, TFLint, KICS) and a plan; apply and destroy are
manual `workflow_dispatch` runs gated by protected GitHub environments (see `../docs/README.md`).

## Adding things

- **Module**: create `deployments/modules/<name>/` with `main.tf`, `variables.tf`, `outputs.tf`. Give every input a description and type.
- **Project**: create `deployments/projects/<project>/<env>/` with the six environment files and a new TFC workspace per environment. Update workflow input descriptions.
- **Environment**: copy an existing environment folder, update `terraform.tfvars` and the workspace name in `backend.tf`. Update workflow input descriptions.

Secrets never go in `terraform.tfvars` — use Terraform Cloud workspace variables or GitHub secrets.

See `AGENTS.md` for full conventions.
