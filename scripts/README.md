# Scripts

Repeatable, non-secret automation for RIMS infrastructure.

## Intended contents

- Bootstrap helpers (e.g. creating Terraform Cloud workspaces)
- Local developer conveniences (fmt/validate wrappers)
- Operational one-off tooling

## Rules

- No credentials, tokens, or access keys — ever. Scripts read secrets from the environment or Terraform Cloud.
- Scripts must be idempotent and safe to re-run.
