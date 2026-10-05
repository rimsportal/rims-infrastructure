# Creates the GitHub OIDC credential used when DT Factory is deployed from
# rims-infrastructure. The existing rims-dt-factory credentials are retained
# during the migration so the previous pipeline can still produce read-only plans.

$ErrorActionPreference = "Stop"

$AppId = "bd4666d9-c71e-4e0a-8662-c1f055922965" # RIMS-DT-FACTORY-DEPLOYMENT
$OwnerRepo = "rimsportal@307976407/rims-infrastructure@1305538121"
$Credentials = @(
  @{
    Name    = "gh-fc-rp-ri-dtf-env-dev"
    Subject = "repo:${OwnerRepo}:environment:dev"
  },
  @{
    Name    = "gh-fc-rp-ri-dtf-env-destroy"
    Subject = "repo:${OwnerRepo}:environment:destroy"
  }
)

foreach ($credential in $Credentials) {
  $existing = az ad app federated-credential list `
    --id $AppId `
    --query "[?name=='$($credential.Name)'].name" `
    --output tsv

  if ($LASTEXITCODE -ne 0) {
    throw "Unable to list federated credentials for $AppId."
  }

  if ($existing -eq $credential.Name) {
    Write-Host "OIDC credential $($credential.Name) already exists."
    continue
  }

  $parameters = New-TemporaryFile
  try {
    @{
      name      = $credential.Name
      issuer    = "https://token.actions.githubusercontent.com"
      subject   = $credential.Subject
      audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json | Set-Content -Path $parameters -Encoding ascii

    az ad app federated-credential create `
      --id $AppId `
      --parameters "@$($parameters.FullName)" | Out-Null

    if ($LASTEXITCODE -ne 0) {
      throw "Failed to create $($credential.Name)."
    }
  }
  finally {
    Remove-Item -LiteralPath $parameters -Force -ErrorAction SilentlyContinue
  }

  Write-Host "Created $($credential.Name) for $($credential.Subject)."
}
