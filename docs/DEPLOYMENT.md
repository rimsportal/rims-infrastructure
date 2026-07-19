# Deploying RIMS Infrastructure (GitHub Actions + Azure OIDC)

State lives in **Azure Storage**; GitHub Actions authenticates to Azure with the
**RIMS-Deployment** service principal via **OIDC** (no stored client secret).

## Identifiers

| Name | Value |
|---|---|
| Service principal (client) id | `80e046d2-a6e6-4ff0-8b2a-89de6a5ba658` |
| Subscription id | `59e1c26e-b22d-451a-b802-231f712f10b4` |
| Tenant id | _fill in — see `az account show --query tenantId -o tsv`_ |

## One-time setup

### 1. Create the remote-state backend

Run the bootstrap script once (as an Owner) — it creates the state resource
group, storage account, container, and grants the SP data access:

```bash
az login
bash scripts/bootstrap-tfstate.sh
```

Values in the script must match `backend.tf`
(`rims-tfstate-rg` / `rimstfstatecin` / `tfstate`). Storage account names are
globally unique — if `rimstfstatecin` is taken, change it in **both** the script
and `backend.tf`.

### 2. Add the OIDC federated credential to RIMS-Deployment

This lets the SP trust tokens from this GitHub repo. Replace `ORG/REPO`:

```bash
az ad app federated-credential create \
  --id 80e046d2-a6e6-4ff0-8b2a-89de6a5ba658 \
  --parameters '{
    "name": "github-rims-infra-dev",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:ORG/REPO:environment:dev",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

The `subject` must match how the workflow runs. The apply/destroy jobs use GitHub
**environments** (`dev`, `destroy`), so use `repo:ORG/REPO:environment:dev` (and a
second credential with `:environment:destroy`). For the plan workflow (runs on
pull requests, no environment) add another with
`subject: repo:ORG/REPO:pull_request`.

### 3. GitHub repository secrets

Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|---|---|
| `ARM_CLIENT_ID` | `80e046d2-a6e6-4ff0-8b2a-89de6a5ba658` |
| `ARM_SUBSCRIPTION_ID` | `59e1c26e-b22d-451a-b802-231f712f10b4` |
| `ARM_TENANT_ID` | your tenant id |
| `POSTGRES_ADMIN_PASSWORD` | strong password for the Postgres admin |
| `JWT_SECRET` | long random string for the backend |

No `ARM_CLIENT_SECRET` and no `TF_TOKEN_*` — OIDC replaces both.

### 4. Protected GitHub environments

Settings → Environments → create `dev` and `destroy` (add required reviewers as
desired). The apply job binds to `dev`; destroy binds to `destroy`.

## Deploy

1. **Plan** (optional): open a PR touching `foundation/**`, or run the *Terraform
   Plan* workflow (`workflow_dispatch`, project `Designstool`, env `dev`).
2. **Apply**: run *Terraform Apply* (`workflow_dispatch`) with project
   `Designstool`, env `dev`. This creates the resource group, PostgreSQL Flexible
   Server, Storage account, and the App Service with connection strings wired in.
3. **Initialize the database once** — allow your IP through the Postgres firewall
   (set `postgres.client_ip` in `terraform.tfvars` or add a temporary rule), then
   from `RIMS-Claude/backend`:
   ```bash
   export DATABASE_URL="postgresql://rimsadmin:<password>@rims-designstool-dev-pg.postgres.database.azure.com:5432/rims?sslmode=require"
   npm run db:init && npm run seed
   ```
4. **Deploy the backend code** via the *Deploy Backend to Azure App Service*
   workflow in the RIMS-Claude repo (needs the `AZURE_WEBAPP_PUBLISH_PROFILE`
   secret and a `dev` environment).
5. Check `https://rims-designstool-dev-api.azurewebsites.net/api/health`.

## Notes

- The SP needs **Contributor** on the subscription (to create resources) and
  **Storage Blob Data Contributor** on the state account (granted by the
  bootstrap script).
- This repo no longer uses Terraform Cloud; `backend.tf` uses the `azurerm`
  backend with `use_oidc` + `use_azuread_auth`.
