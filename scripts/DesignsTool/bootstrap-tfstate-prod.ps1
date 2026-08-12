# Bootstrap the Terraform remote-state backend in Azure Storage and grant the
# RIMS-Deployment service principal data access to it (Azure AD auth).
#
# Run ONCE in PowerShell with Azure CLI installed and logged in as an Owner:
#   az login
#   .\bootstrap-tfstate.ps1
# Values must match backend.tf.

$ErrorActionPreference = "Stop"

# Helper: stop immediately if the previous az command failed.
function Assert-LastExit($what) {
  if ($LASTEXITCODE -ne 0) { throw "FAILED: $what (exit $LASTEXITCODE). Fix the error above, then re-run." }
}

# --- must match foundation/deployments/projects/Designstool/prod/backend.tf ---
$LOCATION        = "centralindia"
$STATE_RG        = "rg-rims-tfstate-prod"
$STATE_SA        = "rimstfstateprod"    # globally unique, 3-24 lowercase alphanumeric
$STATE_CONTAINER = "tfstate-prod"

# RIMS-Deployment service principal (app id) and subscription
$SP_CLIENT_ID    = "80e046d2-a6e6-4ff0-8b2a-89de6a5ba658"
$SUBSCRIPTION_ID = "59e1c26e-b22d-451a-b802-231f712f10b4"

Write-Host "==> Selecting subscription"
az account set --subscription $SUBSCRIPTION_ID
Assert-LastExit "az account set"

Write-Host "==> Active context (verify this is the RIMS subscription):"
az account show --output table
Assert-LastExit "az account show"

Write-Host "==> Registering the Storage resource provider (needed on new subscriptions)"
az provider register --namespace Microsoft.Storage --wait
Assert-LastExit "provider register Microsoft.Storage"

Write-Host "==> Resource group"
az group create --name $STATE_RG --location $LOCATION -o none
Assert-LastExit "az group create"

Write-Host "==> Storage account"
az storage account create --name $STATE_SA --resource-group $STATE_RG --location $LOCATION --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false -o none
Assert-LastExit "az storage account create"

Write-Host "==> Blob container (auth via account key to avoid data-plane RBAC delay)"
az storage container create --name $STATE_CONTAINER --account-name $STATE_SA --auth-mode key -o none
Assert-LastExit "az storage container create"

Write-Host "==> Grant the service principal 'Storage Blob Data Contributor' on the state account"
$SA_ID = az storage account show --name $STATE_SA --resource-group $STATE_RG --query id -o tsv
Assert-LastExit "az storage account show"
az role assignment create --assignee $SP_CLIENT_ID --role "Storage Blob Data Contributor" --scope $SA_ID -o none
Assert-LastExit "role assignment (storage)"

Write-Host "==> Grant the service principal 'Contributor' on the subscription"
az role assignment create --assignee $SP_CLIENT_ID --role "Contributor" --scope "/subscriptions/$SUBSCRIPTION_ID" -o none
Assert-LastExit "role assignment (subscription)"

Write-Host ""
Write-Host "Done. State backend ready: rg=$STATE_RG sa=$STATE_SA container=$STATE_CONTAINER"
