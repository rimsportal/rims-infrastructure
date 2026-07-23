# Modules Split Runbook — rims-infra-core-modules + rims-infrastructure

Extracts the Terraform modules into a versioned repo (`rimsportal/rims-infra-core-modules`)
and points dev/prod at them by git tag. The `rims-infrastructure` edits (module
sources rewired to `?ref=v0.1.0`, private-repo CI auth in the workflows) are
already committed on the working branch — this runbook covers the parts that must
run on your machine / in GitHub.

Target layout:

```
rimsportal/rims-infra-core-modules            # each module a top-level folder, tagged v0.1.0
  app-service/  hub-networking/  identity/  postgresql-flexible-server/
  resource-group/  spoke-networking/  storage-account/

rimsportal/rims-infrastructure     # dev/ + prod/, modules referenced by git tag
  foundation/deployments/projects/DesignsTool/{dev,prod}/main.tf
    source = "git::https://github.com/rimsportal/rims-infra-core-modules.git//<name>?ref=v0.1.0"
```

---

## Step 1 — Create the empty modules repo

On GitHub: **New repository** → owner `rimsportal`, name `rims-infra-core-modules`,
visibility **Private**. **Do NOT** add a README / .gitignore / license — leave it
empty so the first push isn't rejected.

## Step 2 — Populate and tag it (PowerShell)

Copies the current modules out of the infra repo, pushes them, and cuts the
`v0.1.0` tag that dev/prod pin to:

```powershell
cd D:\Projects\RIMS
New-Item -ItemType Directory rims-infra-core-modules | Out-Null
Copy-Item -Recurse "RIMS-INFRASTRUCTURE\foundation\deployments\modules\*" "rims-infra-core-modules\"
cd rims-infra-core-modules
git init -b main
git add .
git commit -m "Initial import of RIMS Terraform modules"
git remote add origin https://github.com/rimsportal/rims-infra-core-modules.git
git push -u origin main
git tag v0.1.0
git push origin v0.1.0
```

Verify on GitHub that the seven module folders are at the repo root and the
`v0.1.0` tag exists (Releases/Tags).

## Step 3 — Give CI read access to the private modules repo (GitHub App)

The org blocks both fine-grained PATs and deploy keys, and recommends **GitHub
Apps**. The workflows mint a short-lived installation token from an App and use it
to clone the modules repo over HTTPS:

```yaml
- uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.MODULES_APP_ID }}
    private-key: ${{ secrets.MODULES_APP_PRIVATE_KEY }}
    owner: rimsportal
    repositories: rims-infra-core-modules
```

Set it up (you must be an org owner):

1. **Create the App** — Org **rimsportal → Settings → Developer settings → GitHub
   Apps → New GitHub App**.
   - **Name:** e.g. `rims-ci-modules-reader` (must be globally unique).
   - **Homepage URL:** anything (e.g. the org URL).
   - **Webhook:** uncheck **Active** (not needed).
   - **Repository permissions → Contents: Read-only**. Leave all else "No access."
   - **Where can this GitHub App be installed:** Only on this account.
   - **Create GitHub App.**

2. **Get credentials** — on the App's page:
   - Note the **App ID** (near the top).
   - **Generate a private key** → downloads a `.pem` file.

3. **Install the App** — App page → **Install App** → install on **rimsportal** →
   **Only select repositories → rims-infra-core-modules** → Install.

4. **Add secrets** to **rims-infrastructure** → Settings → Secrets and variables →
   Actions → New repository secret:
   - `MODULES_APP_ID` = the App ID.
   - `MODULES_APP_PRIVATE_KEY` = the full contents of the `.pem`
     (including the `-----BEGIN/END-----` lines).

5. Delete the local `.pem` after pasting it into the secret.

> The App token is scoped to `rims-infra-core-modules`, Contents-read, and expires
> in ~1 hour — the least-privilege, org-approved option. Add more repos to the
> App's installation later if you split out more private modules.

## Step 4 — Remove the modules from rims-infrastructure and ship

The module folders now live in `rims-infra-core-modules`, so delete them from the infra repo
and commit the rewire (make sure the stale `.git/index.lock` is gone first — see
note below):

```powershell
cd D:\Projects\RIMS\RIMS-INFRASTRUCTURE
git rm -r foundation/deployments/modules
git add -A
git commit -m "Split modules into rims-infra-core-modules; source dev/prod by git tag v0.1.0; CI auth for private modules"
git push origin prod-deploy
```

Open the PR and let pre-checks + the dev/prod plan run. The plan step will clone
`rims-infra-core-modules@v0.1.0` using the GitHub App token, so a green plan confirms the
whole chain works:

```powershell
gh pr create --base main --head prod-deploy `
  --title "Split modules into rims-infra-core-modules; tag-pinned sources" `
  --body "Modules extracted to rimsportal/rims-infra-core-modules, pinned at v0.1.0; workflows clone it via a GitHub App token."
gh pr merge prod-deploy --squash
```

## Step 5 — Deploy prod

```powershell
gh workflow run "Terraform Apply" -f project=DesignsTool -f environment=prod
```

Approve the `prod` environment gate, then watch the run.

---

## Bumping modules later

1. Change a module in `rims-infra-core-modules`, merge to its `main`.
2. Tag a new release: `git tag v0.2.0 && git push origin v0.2.0`.
3. In `rims-infrastructure`, bump `?ref=v0.1.0` → `?ref=v0.2.0` in the env(s) you
   want to adopt it — dev first, then prod after it checks out. This deliberate
   bump is the whole point of tag pinning: prod never moves until you say so.

## Local terraform runs (developers)

To run `terraform init` locally against the private modules repo, use SSH access
to GitHub (your own SSH key added to your account under Settings → SSH keys), and
rewrite HTTPS to SSH once:

```powershell
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

Then `terraform init` clones the modules over SSH with your key. (Anyone with
read access to `rims-infra-core-modules` and an SSH key on their account can run
it.)

## Note: stale git lock

If git reports `Unable to create '.git/index.lock': File exists`, clear it:

```powershell
Remove-Item "D:\Projects\RIMS\RIMS-INFRASTRUCTURE\.git\*.lock" -Force
```
