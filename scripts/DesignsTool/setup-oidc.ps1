# Creates/updates GitHub OIDC federated credentials on the RIMS-Deployment app
# so GitHub Actions can authenticate to Azure WITHOUT a client secret.
#
# This tenant issues the "immutable ID" style OIDC subject, e.g.
#   repo:rimsportal@307976407/rims-infrastructure@1305538121:pull_request
# so the credential subjects include the numeric org and repo IDs.
#
# IMPORTANT: GitHub presents the org name LOWERCASE in the token ('rimsportal'),
# and subject matching is case-sensitive. The subjects below MUST stay lowercase
# even though the org displays as RIMSPORTAL in the Azure portal.
#
# Azure also requires the (issuer, subject) pair to be UNIQUE per app. So this
# script deletes the legacy 'github-rims-infra-*' credentials FIRST (they hold the
# subjects we want), then (re)creates the convention creds via delete-then-create.
#
# Naming convention (federated credential names):
#   gh = github, fc = federated credential, rp = rimsportal, ri = rims-infrastructure
#   -> gh-fc-rp-ri-<entity>   e.g. gh-fc-rp-ri-env-prod
#
# Run in PowerShell, logged in as someone who can manage the app registration:
#   az login
#   .\setup-oidc.ps1

$ErrorActionPreference = "Stop"

$APP_ID = "80e046d2-a6e6-4ff0-8b2a-89de6a5ba658"   # RIMS-Deployment

# Owner/repo with their numeric IDs, exactly as GitHub presents them in the
# OIDC `sub` claim (confirmed against the AADSTS700213 error's presented subject):
#   org  rimsportal          -> id 307976407
#   repo rims-infrastructure -> id 1305538121
$OWNER_REPO = "rimsportal@307976407/rims-infrastructure@1305538121"

function Test-Cred($name) {
  return (az ad app federated-credential list --id $APP_ID --query "[?name=='$name'].name" -o tsv 2>$null) -eq $name
}

function Remove-Cred($name) {
  if (Test-Cred $name) {
    Write-Host "==> deleting $name"
    az ad app federated-credential delete --id $APP_ID --federated-credential-id $name 2>$null | Out-Null
  }
}

# Delete-then-create avoids the update path (which trips on list caching) and
# guarantees the subject is free before we claim it.
function Set-Cred($name, $subject) {
  Remove-Cred $name
  $tmp = New-TemporaryFile
  @{
    name      = $name
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = $subject
    audiences = @("api://AzureADTokenExchange")
  } | ConvertTo-Json | Set-Content -Path $tmp -Encoding ascii
  Write-Host "==> creating $name  ($subject)"
  az ad app federated-credential create --id $APP_ID --parameters "@$($tmp.FullName)"
  if ($LASTEXITCODE -ne 0) { throw "Failed for $name" }
  Remove-Item $tmp -Force
}

# --- Phase 1: remove legacy duplicates that hold the subjects we want ----------
Remove-Cred "github-rims-infra-dev"
Remove-Cred "github-rims-infra-prod"
Remove-Cred "github-rims-infra-destroy"
Remove-Cred "github-rims-infra-pr"
Remove-Cred "github-rims-infra-main"

Write-Host "==> waiting for deletes to propagate"
Start-Sleep -Seconds 8

# --- Phase 2: (re)create under the naming convention, lowercase subjects -------

# Terraform Apply runs in the 'dev' GitHub environment.
Set-Cred "gh-fc-rp-ri-env-dev" "repo:${OWNER_REPO}:environment:dev"

# Terraform Apply runs in the 'qa' GitHub environment.
Set-Cred "gh-fc-rp-ri-env-qa" "repo:${OWNER_REPO}:environment:qa"

# Terraform Apply runs in the 'prod' GitHub environment.
Set-Cred "gh-fc-rp-ri-env-prod" "repo:${OWNER_REPO}:environment:prod"

# Terraform Destroy runs in the 'destroy' GitHub environment.
Set-Cred "gh-fc-rp-ri-env-destroy" "repo:${OWNER_REPO}:environment:destroy"

# Terraform Plan runs on pull requests (no environment).
Set-Cred "gh-fc-rp-ri-pr" "repo:${OWNER_REPO}:pull_request"

# Terraform Plan run MANUALLY (workflow_dispatch) on the main branch.
Set-Cred "gh-fc-rp-ri-branch-main" "repo:${OWNER_REPO}:ref:refs/heads/main"

Write-Host ""
Write-Host "Done. Credentials follow gh-fc-rp-ri-* with lowercase subjects; legacy duplicates removed."
Write-Host "Verify: az ad app federated-credential list --id $APP_ID --query ""[].{name:name, subject:subject}"" -o table"
