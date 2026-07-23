# Creates/updates GitHub OIDC federated credentials on the RIMS-Deployment app
# so GitHub Actions can authenticate to Azure WITHOUT a client secret.
#
# This tenant issues the "immutable ID" style OIDC subject, e.g.
#   repo:rimsportal@<ORG_ID>/rims-infrastructure@<REPO_ID>:pull_request
# so the credential subjects must include the numeric org and repo IDs. Those IDs
# change whenever the org or repo is recreated, so the script reads them live from
# the GitHub API instead of hardcoding them.
#
# Run in PowerShell, logged in as someone who can manage the app registration:
#   az login
#   .\setup-oidc.ps1
#
# For a PRIVATE repo, the repo-id lookup needs a token. Provide one first:
#   $env:GITHUB_TOKEN = "ghp_..."   # a PAT with repo read access
# (Public repos work without a token.)

$ErrorActionPreference = "Stop"

$APP_ID = "80e046d2-a6e6-4ff0-8b2a-89de6a5ba658"   # RIMS-Deployment

# GitHub owner (org) and repository names.
$OWNER = "rimsportal"
$REPO  = "rims-infrastructure"

# Resolve numeric IDs from the GitHub API and build the immutable-ID subject
# prefix: "<OWNER>@<ORG_ID>/<REPO>@<REPO_ID>".
function Get-GitHubJson($url) {
  $headers = @{ "User-Agent" = "rims-setup-oidc"; "Accept" = "application/vnd.github+json" }
  if ($env:GITHUB_TOKEN) { $headers["Authorization"] = "Bearer $($env:GITHUB_TOKEN)" }
  return Invoke-RestMethod -Uri $url -Headers $headers -Method Get
}

Write-Host "==> Resolving GitHub numeric IDs for $OWNER/$REPO"
try {
  $ownerId = (Get-GitHubJson "https://api.github.com/users/$OWNER").id
  $repoId  = (Get-GitHubJson "https://api.github.com/repos/$OWNER/$REPO").id
} catch {
  throw "Could not read GitHub IDs. If the repo is private, set `$env:GITHUB_TOKEN to a PAT with repo read access, then re-run. Underlying error: $($_.Exception.Message)"
}
if (-not $ownerId -or -not $repoId) { throw "GitHub returned empty IDs for $OWNER/$REPO." }

$OWNER_REPO = "$OWNER@$ownerId/$REPO@$repoId"
Write-Host "    subject prefix: repo:$OWNER_REPO"

function Set-FederatedCred($name, $subject) {
  $tmp = New-TemporaryFile
  @{
    name      = $name
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = $subject
    audiences = @("api://AzureADTokenExchange")
  } | ConvertTo-Json | Set-Content -Path $tmp -Encoding ascii

  $existing = az ad app federated-credential list --id $APP_ID --query "[?name=='$name'].name" -o tsv 2>$null
  if ($existing -eq $name) {
    Write-Host "==> updating $name  ($subject)"
    az ad app federated-credential update --id $APP_ID --federated-credential-id $name --parameters "@$($tmp.FullName)"
  } else {
    Write-Host "==> creating $name  ($subject)"
    az ad app federated-credential create --id $APP_ID --parameters "@$($tmp.FullName)"
  }
  if ($LASTEXITCODE -ne 0) { throw "Failed for $name" }
  Remove-Item $tmp -Force
}

# Terraform Apply runs in the 'dev' GitHub environment.
Set-FederatedCred "github-rims-infra-dev" "repo:${OWNER_REPO}:environment:dev"

# Terraform Apply runs in the 'prod' GitHub environment.
Set-FederatedCred "github-rims-infra-prod" "repo:${OWNER_REPO}:environment:prod"

# Terraform Destroy runs in the 'destroy' GitHub environment.
Set-FederatedCred "github-rims-infra-destroy" "repo:${OWNER_REPO}:environment:destroy"

# Terraform Plan runs on pull requests (no environment).
Set-FederatedCred "github-rims-infra-pr" "repo:${OWNER_REPO}:pull_request"

# Terraform Plan run MANUALLY (workflow_dispatch) on the main branch.
Set-FederatedCred "github-rims-infra-main" "repo:${OWNER_REPO}:ref:refs/heads/main"

Write-Host ""
Write-Host "Done. Federated credential subjects updated to the ID-based form."
Write-Host "Verify: az ad app federated-credential list --id $APP_ID -o table"
