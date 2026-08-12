#!/usr/bin/env bash
# Bootstrap the Terraform remote-state backend in Azure Storage and grant the
# RIMS-Deployment service principal data access to it (Azure AD auth, no keys).
#
# Run ONCE with an account that can create resources + assign roles
# (e.g. `az login` as an Owner). Values must match backend.tf.
set -euo pipefail

# --- must match foundation/deployments/projects/Designstool/dev/backend.tf ---
LOCATION="centralindia"
STATE_RG="rims-tfstate-rg"
STATE_SA="rimstfstatecin"          # globally unique, 3-24 lowercase alphanumeric
STATE_CONTAINER="tfstate"

# RIMS-Deployment service principal (object/app id) and subscription
SP_CLIENT_ID="80e046d2-a6e6-4ff0-8b2a-89de6a5ba658"
SUBSCRIPTION_ID="59e1c26e-b22d-451a-b802-231f712f10b4"

az account set --subscription "$SUBSCRIPTION_ID"

echo "==> Resource group"
az group create --name "$STATE_RG" --location "$LOCATION" -o none

echo "==> Storage account (AAD-only, no shared keys)"
az storage account create \
  --name "$STATE_SA" \
  --resource-group "$STATE_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  -o none

echo "==> Blob container"
az storage container create \
  --name "$STATE_CONTAINER" \
  --account-name "$STATE_SA" \
  --auth-mode login \
  -o none

echo "==> Grant the service principal 'Storage Blob Data Contributor' on the state account"
SA_ID=$(az storage account show --name "$STATE_SA" --resource-group "$STATE_RG" --query id -o tsv)
az role assignment create \
  --assignee "$SP_CLIENT_ID" \
  --role "Storage Blob Data Contributor" \
  --scope "$SA_ID" \
  -o none

echo "==> Grant the service principal 'Contributor' on the subscription (to build resources)"
az role assignment create \
  --assignee "$SP_CLIENT_ID" \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  -o none || echo "   (skip if already assigned)"

echo "Done. State backend ready: rg=$STATE_RG sa=$STATE_SA container=$STATE_CONTAINER"
