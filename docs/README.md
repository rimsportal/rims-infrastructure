# Docs

Architecture, operational, and onboarding documentation for RIMS infrastructure.

## Intended contents

- Architecture diagrams and decisions (API Gateway, Auth/Store/Image/PDF/Approval/Notification services, PostgreSQL, Blob Storage)
- Operational runbooks (deploy, rollback, destroy)
- Onboarding guides for new engineers

## CI/CD requirements (values live in GitHub, never in this repo)

### Required GitHub secrets

| Secret | Purpose |
|---|---|
| `TF_TOKEN_APP_TERRAFORM_IO` | Terraform Cloud API token |
| `ARM_CLIENT_ID` | Azure service principal client ID |
| `ARM_CLIENT_SECRET` | Azure service principal secret |
| `ARM_SUBSCRIPTION_ID` | Azure subscription |
| `ARM_TENANT_ID` | Azure AD tenant |

### Required protected GitHub environments

Configure before running apply or destroy workflows, with required reviewers:

- `dev`, `qa`, `preprod`, `prod` — bound by Terraform Apply
- `destroy` — bound by Terraform Destroy

Never commit credential values to any file in this repository.
