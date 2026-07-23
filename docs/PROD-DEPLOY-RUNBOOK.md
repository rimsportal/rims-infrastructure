# Prod Deployment Runbook — DesignsTool

Dev is live. This is the exact sequence to bring **prod** up. State backend
(`rimstfstateprod`) is already bootstrapped, so the remaining gaps are the prod
**OIDC credential** and the **GitHub `prod` environment**. Everything runs under
your own Azure / GitHub admin credentials.

Identifiers (from `docs/DEPLOYMENT.md`):

| Name | Value |
|---|---|
| Service principal (client) id | `80e046d2-a6e6-4ff0-8b2a-89de6a5ba658` |
| Subscription id | `59e1c26e-b22d-451a-b802-231f712f10b4` |
| GitHub owner / repo | `rimsportal/rims-infrastructure` |
| OIDC subject form | `repo:rimsportal@<ORG_ID>/rims-infrastructure@<REPO_ID>:environment:prod` (numeric IDs resolved automatically by the script) |

---

## Step 1 — Create the prod OIDC federated credential (one-time)

Without this, the prod apply fails Azure login with
`AADSTS700213 No matching federated identity`. `scripts/setup-oidc.ps1` now
targets the `rimsportal/rims-infrastructure` repo, resolves the numeric org/repo
IDs from the GitHub API automatically, includes the prod credential, and is
idempotent — just run it:

```powershell
az login
# Private repo? Set a PAT with repo read access so the repo-id lookup works:
$env:GITHUB_TOKEN = "ghp_..."
cd D:\Projects\RIMS\RIMS-INFRASTRUCTURE\scripts
.\setup-oidc.ps1
```

The script prints the resolved subject prefix
(`repo:rimsportal@<ORG_ID>/rims-infrastructure@<REPO_ID>`). Verify it landed:

```powershell
az ad app federated-credential list --id 80e046d2-a6e6-4ff0-8b2a-89de6a5ba658 -o table
```

You should see `github-rims-infra-prod` in the list.

---

## Step 2 — Create the protected GitHub `prod` environment (one-time)

The apply job runs `environment: prod`, which is also your approval gate.

GitHub repo → **Settings → Environments → New environment** → name it `prod`.
Add yourself under **Required reviewers** so prod applies pause for approval
(recommended for prod). Secrets are repo-level and already set for dev
(`ARM_CLIENT_ID`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`,
`POSTGRES_ADMIN_PASSWORD`, `JWT_SECRET`), so nothing to re-add here.

> Note: environment protection rules require a public repo on GitHub Free, or
> Pro/Team on a private repo. If prod doesn't pause for approval, that's why.

---

## Step 3 — (Optional) Plan prod first

GitHub → **Actions → Terraform Plan → Run workflow**, inputs:
`project = DesignsTool`, `environment = prod`. Review the plan — it should show
the prod resource group, PostgreSQL Flexible Server (`rims-designstool-prod-pg`),
Storage account (`rimsdtoolprodsa`), and App Service (`rims-designstool-prod-api`)
being **created** (all new, no destroys).

---

## Step 4 — Apply prod

GitHub → **Actions → Terraform Apply → Run workflow**, inputs:
`project = DesignsTool`, `environment = prod`. The run pauses on the `prod`
environment gate → open the run → **Review deployments → Approve**. Terraform then
creates the resource group, Postgres, Storage, and App Service with connection
strings wired in.

> Case matters: the folder is `foundation/deployments/projects/DesignsTool/prod`
> — use `DesignsTool` (capital D, T) and `prod` exactly, since the Linux runner is
> case-sensitive.

---

## Step 5 — Initialize the prod database (one-time)

Allow your workstation IP through the Postgres firewall — set `postgres.client_ip`
to your public IP in
`foundation/deployments/projects/DesignsTool/prod/terraform.tfvars` and re-apply,
or add a temporary firewall rule in the portal. Then from `RIMS-Claude/backend`:

```bash
export DATABASE_URL="postgresql://rimsadmin:<PROD_PASSWORD>@rims-designstool-prod-pg.postgres.database.azure.com:5432/rims?sslmode=require"
npm run db:init && npm run seed
```

Use the **prod** admin password (the `POSTGRES_ADMIN_PASSWORD` secret value).
Remove the temporary firewall rule / reset `client_ip` to `""` afterward.

---

## Step 6 — Deploy backend code + verify

Run the **Deploy Backend to Azure App Service** workflow in the `RIMS-Claude`
repo targeting prod (needs the prod `AZURE_WEBAPP_PUBLISH_PROFILE` secret and a
`prod` environment on that repo). Then check:

```
https://rims-designstool-prod-api.azurewebsites.net/api/health
```

A healthy response means prod is live.

---

## Rollback / teardown

If you need to tear prod down: **Actions → Terraform Destroy** with
`project = DesignsTool`, `environment = prod` (gated by the `destroy`
environment). The state backend (`rg-rims-tfstate-prod`) is intentionally left in
place.

---

## Gotchas specific to prod

- **`STATIC_OTP = "123456"`** is set in `prod/terraform.tfvars` (`app_settings`).
  That's a hardcoded test OTP — fine for dev, a security hole in prod. Consider
  removing it or gating it before real users hit the system.
- `NODE_ENV` is correctly `production` in prod tfvars (dev uses `development`).
- The tfvars comments still mention "Terraform Cloud" workspace variables — that's
  stale; secrets now flow via GitHub Secrets → `TF_VAR_*`. No action needed.
