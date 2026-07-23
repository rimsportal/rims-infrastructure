# Infrastructure — Deployment Strategy

How we deploy Azure infrastructure with Terraform and GitHub Actions. This is a
reusable strategy: replace the placeholders in `<...>` with your own values.

> **No secrets in this document.** Everything in `<...>` is a placeholder.
> Real credentials live only in Azure and GitHub Secrets — never in Git.

Placeholders used throughout:

| Placeholder | Meaning |
|---|---|
| `<INFRA_REPO>` | the infrastructure Git repository |
| `<ORG>` | GitHub organization / owner |
| `<SUBSCRIPTION_ID>` | target Azure subscription |
| `<TENANT_ID>` | Azure AD tenant |
| `<CLIENT_ID>` | deployment service principal (app/client) ID |
| `<STATE_RG>` | resource group holding Terraform state |
| `<STATE_SA>` | storage account holding Terraform state (globally unique) |
| `<STATE_CONTAINER>` | blob container for state |
| `<PROJECT>` / `<ENV>` | project name / environment name (e.g. dev) |

---

## 1. Approach

- **Infrastructure as Code** with **Terraform** (`hashicorp/azurerm ~> 3.100`).
- **GitOps pipeline** in **GitHub Actions**: change → PR → automated checks →
  merge → manual approval → `terraform apply`.
- **Remote state** in **Azure Storage** (not Terraform Cloud), accessed with
  **Azure AD auth** (no storage account keys).
- **CI authenticates to Azure with GitHub OIDC** federated credentials on a
  deployment service principal. **No client secret is stored anywhere.**

---

## 2. Repository layout

```text
<INFRA_REPO>/
  .github/workflows/
    pre-checks.yml          # fmt + TFLint + KICS (on PR/push)
    terraform-plan.yml      # plan (on PR, and manual)
    terraform-apply.yml     # apply on merge to main, gated by approval
    terraform-destroy.yml   # manual, gated
  scripts/
    bootstrap-tfstate.ps1   # one-time: create remote state backend + role assignments
    setup-oidc.ps1          # one-time: create OIDC federated credentials
  foundation/
    deployments/
      modules/              # reusable modules (main.tf, variables.tf, outputs.tf each)
      projects/<PROJECT>/<ENV>/   # backend.tf, locals.tf, main.tf, outputs.tf, terraform.tfvars, variables.tf
  deployment-strategy.md
```

Remote-state backend block in every environment's `backend.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "<STATE_RG>"
  storage_account_name = "<STATE_SA>"
  container_name       = "<STATE_CONTAINER>"
  key                  = "<PROJECT>/<ENV>.terraform.tfstate"
  use_oidc             = true
  use_azuread_auth     = true
}
```

---

## 3. Prerequisites

- **Azure CLI** (`az version`), logged in with `az login`.
- **Terraform** >= 1.5.0 (for optional local plan/validate; CI runs its own).
- Access to the infrastructure GitHub repo.
- To **bootstrap**: **Owner** (or Contributor + User Access Administrator) on the
  subscription. Routine deploys need only the service principal.

Get your identifiers (never commit them):

```powershell
az account show --query id -o tsv         # <SUBSCRIPTION_ID>
az account show --query tenantId -o tsv   # <TENANT_ID>
```

---

## 4. One-time bootstrap (per environment)

Skip if the environment already exists.

### 4.1 Remote state backend

State lives in Azure Storage with AAD auth. The script creates the resource
group, storage account, container, and grants the service principal data access.

```powershell
az login
cd <INFRA_REPO>/scripts
.\bootstrap-tfstate.ps1
```

`bootstrap-tfstate.ps1` does:

1. Creates the state resource group `<STATE_RG>`.
2. Creates the state storage account `<STATE_SA>` (StorageV2, TLS1.2, no public blob).
3. Creates the state blob container `<STATE_CONTAINER>`.
4. Grants the service principal **Storage Blob Data Contributor** on the state account.
5. Grants the service principal **Contributor** on the subscription (to build resources).

> Storage account names are globally unique. If `<STATE_SA>` is taken, change it in
> **both** the script and every `backend.tf`.

### 4.2 OIDC federated credentials (how CI logs into Azure with no secret)

GitHub Actions presents a short-lived OIDC token; Azure trusts it via **federated
identity credentials** on the deployment service principal. A script creates them
so it's repeatable.

```powershell
az login
cd <INFRA_REPO>/scripts
.\setup-oidc.ps1
```

`setup-oidc.ps1` creates/updates one credential per pipeline trigger:

| Credential | Subject suffix | Used by |
|---|---|---|
| environment (deploy) | `:environment:<ENV>` | Terraform Apply |
| environment (destroy) | `:environment:destroy` | Terraform Destroy |
| pull request | `:pull_request` | Terraform Plan on PRs |
| default branch | `:ref:refs/heads/main` | Manual plan on `main` |

**How the script builds the subject.** Some tenants issue *immutable ID* OIDC
subjects that contain the numeric org and repo IDs (not just names), e.g.:

```
repo:<ORG>@<ORG_ID>/<REPO>@<REPO_ID>:environment:<ENV>
```

So the script:

1. Reads the numeric IDs from the GitHub API
   (`https://api.github.com/users/<ORG>` and `.../repos/<ORG>/<REPO>`).
2. Builds each subject as `repo:<ORG>@<ORG_ID>/<REPO>@<REPO_ID>:<trigger>`.
3. Calls `az ad app federated-credential create` (or `update` if it exists) with:
   - issuer `https://token.actions.githubusercontent.com`
   - audience `api://AzureADTokenExchange`

The script is **idempotent** — re-running updates existing credentials instead of
failing. If a repo is recreated, its numeric ID changes, so re-run the script.

> If your tenant uses the standard (name-only) subject, it is simply
> `repo:<ORG>/<REPO>:<trigger>` — the script handles whichever form the API
> returns.

Verify:

```powershell
az ad app federated-credential list --id <CLIENT_ID> -o table
```

### 4.3 GitHub configuration

**Repository secrets** (Settings → Secrets and variables → Actions) — IDs plus any
application secrets your Terraform consumes; **no client secret**:

| Secret | Notes |
|---|---|
| `ARM_CLIENT_ID` | deployment service principal app/client ID |
| `ARM_SUBSCRIPTION_ID` | target subscription |
| `ARM_TENANT_ID` | Azure AD tenant |
| `TF_VAR_<name>` … | any sensitive Terraform variables (passwords, keys) |

**Protected environments** (Settings → Environments): create `<ENV>` with
**Required reviewers** (the apply approval gate) and `destroy`.

> Environment protection rules need a **public repo** on GitHub Free, or Pro/Team
> on a private repo.

**Branch protection** (`main`): require a pull request and the `pre-checks` and
`plan` status checks before merging.

---

## 5. How the pipeline works (routine deploys)

```
 branch + edit foundation/**  ->  Pull Request
        |                              |
        |                     pre-checks (fmt, TFLint, KICS)
        |                     plan (terraform plan via OIDC)
        v                              |
     review + approve PR  ---------> merge to main
                                       |
                              terraform-apply.yml starts
                                       |
                        PAUSES on "<ENV>" environment approval
                                       |
                               Approve in Actions
                                       |
                        terraform apply -auto-approve  ->  Azure
```

Step by step:

1. **Create a branch**, edit Terraform under `foundation/`, open a **PR** to `main`.
2. On the PR, two workflows run automatically:
   - **Pre-checks** — `terraform fmt -check`, **TFLint**, **KICS** security scan.
   - **Plan** — `terraform init` (OIDC login to the state backend) + `validate` + `plan`.
3. **Review the plan**, get approval, and **merge to `main`**.
4. **Terraform Apply** triggers on the merge and **pauses on the `<ENV>`
   environment approval** (required reviewer). Approve it in the Actions run
   (*Review deployments* → **Approve**).
5. Apply authenticates via OIDC and runs `terraform apply -auto-approve`.

Manual runs are available from **Actions → Run workflow** (they take `project`
and `environment` inputs).

### Configuration & secrets flow

- Non-secret values live in `foundation/deployments/projects/<PROJECT>/<ENV>/terraform.tfvars`.
- Secret values are **never** in tfvars. Workflows pass them as `TF_VAR_<name>`
  environment variables sourced from GitHub Secrets; Terraform consumes them as
  `variable "<name>" { sensitive = true }`.

---

## 6. Adding a new project or environment

- **New environment**: copy an existing `foundation/deployments/projects/<PROJECT>/<ENV>/`
  folder, update `terraform.tfvars` and the `key` in `backend.tf`; add an OIDC
  credential + protected environment if it uses a new GitHub environment name;
  run Plan then Apply.
- **New module**: add under `foundation/deployments/modules/<name>/` with
  `main.tf`, `variables.tf`, `outputs.tf`; call it from the environment's `main.tf`.
- Keep everything `terraform fmt -recursive` clean (pre-checks enforce it).

---

## 7. Destroy

Use **Actions → Terraform Destroy** (gated by the protected `destroy`
environment). Accepts a `project` + `environment` (or `all`). The remote state
backend (`<STATE_RG>`) is intentionally **not** destroyed by the workflow —
remove it manually only when fully decommissioning.

---

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `terraform init` 403 `AuthorizationPermissionMismatch` | Identity lacks the data role on the state account | Grant **Storage Blob Data Contributor** on the state storage account (bootstrap does this for the SP; grant your own user for local runs) |
| OIDC 401 `AADSTS700213 No matching federated identity` | Credential subject doesn't match GitHub's presented subject | Re-run `setup-oidc.ps1` (matches the subject the API returns) |
| `pre-checks` fmt fails | Files not formatted | `terraform fmt -recursive` from `foundation/`, commit |
| `tflint` "command line arguments dropped" | Old invocation passed a path argument | Run from `foundation/` with `--recursive` |
| Apply/plan "working directory ... not found" | Case mismatch (Linux runner is case-sensitive) | Match the project/environment folder casing exactly to the workflow inputs |
| Apply not pausing for approval | Environment has no required reviewer, or repo is private on Free plan | Add a required reviewer; make the repo public or upgrade the plan |

---

## 9. Bootstrap checklist (copy per environment)

- [ ] `az login` as an Owner
- [ ] `scripts/bootstrap-tfstate.ps1` — state backend + role assignments
- [ ] `scripts/setup-oidc.ps1` — federated credentials on the service principal
- [ ] `az ad app federated-credential list --id <CLIENT_ID> -o table` — verify credentials
- [ ] GitHub secrets: `ARM_CLIENT_ID`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`, and any `TF_VAR_<name>`
- [ ] Protected environments `<ENV>` (required reviewer) + `destroy`
- [ ] Branch protection on `main` requiring `pre-checks` + `plan`
- [ ] Open PR → checks pass → merge → approve Apply → resources created
