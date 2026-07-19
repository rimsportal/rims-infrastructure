# Creates GitHub OIDC federated credentials on the RIMS-Deployment app so
# GitHub Actions can authenticate to Azure WITHOUT a client secret.
#
# Run once in PowerShell, logged in as someone who can manage the app
# registration (Application Administrator / Owner of the app):
#   az login
#   .\setup-oidc.ps1

$ErrorActionPreference = "Stop"

$APP_ID = "80e046d2-a6e6-4ff0-8b2a-89de6a5ba658"   # RIMS-Deployment
$REPO   = "SharadDevOps/rims-infrastructure"

function New-FederatedCred($name, $subject) {
  # Idempotent: skip if a credential with this name already exists.
  $existing = az ad app federated-credential list --id $APP_ID --query "[?name=='$name'].name" -o tsv 2>$null
  if ($existing -eq $name) {
    Write-Host "==> $name already exists - skipping"
    return
  }

  $tmp = New-TemporaryFile
  @{
    name      = $name
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = $subject
    audiences = @("api://AzureADTokenExchange")
  } | ConvertTo-Json | Set-Content -Path $tmp -Encoding ascii

  Write-Host "==> $name  ($subject)"
  az ad app federated-credential create --id $APP_ID --parameters "@$($tmp.FullName)"
  if ($LASTEXITCODE -ne 0) { throw "Failed to create $name" }
  Remove-Item $tmp -Force
}

# Terraform Apply runs in the 'dev' GitHub environment.
New-FederatedCred "github-rims-infra-dev" "repo:${REPO}:environment:dev"

# Terraform Destroy runs in the 'destroy' GitHub environment.
New-FederatedCred "github-rims-infra-destroy" "repo:${REPO}:environment:destroy"

# Terraform Plan runs on pull requests (no environment).
New-FederatedCred "github-rims-infra-pr" "repo:${REPO}:pull_request"

# Terraform Plan run MANUALLY (workflow_dispatch) on the main branch.
New-FederatedCred "github-rims-infra-main" "repo:${REPO}:ref:refs/heads/main"

Write-Host ""
Write-Host "Done. Three federated credentials created on RIMS-Deployment ($APP_ID)."
Write-Host "Verify: az ad app federated-credential list --id $APP_ID -o table"
