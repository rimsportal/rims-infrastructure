# Bootstraps the least-privilege Microsoft Graph access required for the
# DT Factory Terraform deployment identity to manage application registrations
# that it owns. The identity is also made an owner of the existing API
# registration so Terraform can pre-authorize the two mobile clients.

$ErrorActionPreference = "Stop"

$DeploymentApplicationId = "bd4666d9-c71e-4e0a-8662-c1f055922965"
$ApiApplicationId = "1c7d624c-c414-4f77-b8f9-ff0cfc42c873"
$MicrosoftGraphApplicationId = "00000003-0000-0000-c000-000000000000"
$ApplicationReadWriteOwnedByRoleId = "18a4783c-866b-4cc7-a460-3d5e5662c884"

$existingPermission = az ad app permission list `
  --id $DeploymentApplicationId `
  --query "[?resourceAppId=='$MicrosoftGraphApplicationId'].resourceAccess[?id=='$ApplicationReadWriteOwnedByRoleId'].id | [0]" `
  --output tsv

if ($LASTEXITCODE -ne 0) {
  throw "Unable to inspect Microsoft Graph permissions for the deployment identity."
}

if ([string]::IsNullOrWhiteSpace($existingPermission)) {
  az ad app permission add `
    --id $DeploymentApplicationId `
    --api $MicrosoftGraphApplicationId `
    --api-permissions "$ApplicationReadWriteOwnedByRoleId=Role" `
    --only-show-errors

  if ($LASTEXITCODE -ne 0) {
    throw "Unable to add Application.ReadWrite.OwnedBy."
  }
}

az ad app permission admin-consent `
  --id $DeploymentApplicationId `
  --only-show-errors

if ($LASTEXITCODE -ne 0) {
  throw "Unable to grant admin consent for Application.ReadWrite.OwnedBy."
}

$deploymentServicePrincipalId = az ad sp show `
  --id $DeploymentApplicationId `
  --query id `
  --output tsv

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($deploymentServicePrincipalId)) {
  throw "Unable to resolve the DT Factory deployment service principal."
}

$existingOwner = az ad app owner list `
  --id $ApiApplicationId `
  --query "[?id=='$deploymentServicePrincipalId'].id | [0]" `
  --output tsv

if ($LASTEXITCODE -ne 0) {
  throw "Unable to inspect owners of the DT Factory API registration."
}

if ([string]::IsNullOrWhiteSpace($existingOwner)) {
  az ad app owner add `
    --id $ApiApplicationId `
    --owner-object-id $deploymentServicePrincipalId `
    --only-show-errors

  if ($LASTEXITCODE -ne 0) {
    throw "Unable to add the deployment identity as an owner of the API registration."
  }
}

Write-Host "DT Factory mobile identity permissions are configured."
