# Creates/updates GitHub OIDC federated credentials on the RIMS-Deployment app
# so GitHub Actions can authenticate to Azure WITHOUT a client secret.
#
# This repo issues the "immutable ID" style OIDC subject, e.g.
#   repo:SharadDevOps@150069621/rims-infrastructure@1305538121:pull_request
# so the credential subjects below must include those numeric IDs.
#
# Run in PowerShell, logged in as someone who can manage the app registration:
#   az login
#   .\setup-oidc.ps1

$ErrorActionPreference = "Stop"

$APP_ID = "80e046d2-a6e6-4ff0-8b2a-89de6a5ba658"   # RIMS-Deployment

# Owner/repo with their numeric IDs, exactly as GitHub presents them in the
# OIDC `sub` claim. Owner id = 150069621, repo id = 1305538121.
$OWNER_REPO = "SharadDevOps@150069621/rims-infrastructure@1305538121"

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

# Terraform Destroy runs in the 'destroy' GitHub environment.
Set-FederatedCred "github-rims-infra-destroy" "repo:${OWNER_REPO}:environment:destroy"

# Terraform Plan runs on pull requests (no environment).
Set-FederatedCred "github-rims-infra-pr" "repo:${OWNER_REPO}:pull_request"

# Terraform Plan run MANUALLY (workflow_dispatch) on the main branch.
Set-FederatedCred "github-rims-infra-main" "repo:${OWNER_REPO}:ref:refs/heads/main"

Write-Host ""
Write-Host "Done. Federated credential subjects updated to the ID-based form."
Write-Host "Verify: az ad app federated-credential list --id $APP_ID -o table"
