# AGENT.md — infra-agent

> **Scope**: `infra/` exclusively.
> Do NOT touch `back/`, `front/`, or any root file.

---

## Role

Provision and maintain the AWS infrastructure for amap-en-ligne's Lambda deployment:
DynamoDB table, Lambda function, API Gateway, Cognito User Pool, and supporting storage.

---

## Directory layout

```
infra/
  AGENT.md               ← this file
  CLAUDE.md              ← Claude Code entry (imports this file)
  README.md
  main.tf                ← root module — wires all child modules
  locals.tf
  variables.tf
  outputs.tf
  versions.tf
  backend.tf             ← remote state config
  terraform.tfvars       ← environment-specific values (not committed)
  Makefile               ← convenience targets (plan, apply, destroy)
  bootstrap/             ← one-time bootstrap resources (remote state bucket)
  modules/
    api_gateway/         ← API Gateway V2 HTTP API
    cognito/             ← Cognito User Pool + groups + resource server + app client
    dynamo/              ← DynamoDB single-table (pk, sk) + GSIs
    lambda/              ← Lambda function + IAM role + log group
    storage/             ← S3 bucket for Lambda artifact
```

---

## Safety rules

- **Always `plan` before `apply`** — never run `terraform apply` without reviewing the plan output first.
- **Never `destroy` without explicit user confirmation** — even for a single resource. State this limitation and ask before proceeding.
- **No `terraform.tfvars` edits without asking** — this file contains environment-specific values; confirm intent before changing.
- **No module refactors** — do not move resources between modules or rename outputs/variables that other modules consume without checking all references.

---

## Terraform conventions

- Use `terraform fmt` before committing any `.tf` file.
- Variable names use `snake_case`; resource labels use `snake_case`.
- Outputs from child modules must be re-exported through the root `outputs.tf` if consumed by other modules or by CI.
- Tag all taggable resources with at least `Project = "amap-en-ligne"` and `Environment = var.environment`.
- Prefer `lifecycle { prevent_destroy = true }` on stateful resources (DynamoDB table, Cognito User Pool).

---

## Key resources

| Module | Key resource | Notes |
|--------|-------------|-------|
| `dynamo` | DynamoDB table `data` (single-table) | pk + sk, 3 GSIs: `by_cursor`, `by_organization_name`, `by_admin_email` |
| `cognito` | User Pool + app client | `USER_PASSWORD_AUTH` (no SRP), custom attribute `custom:producer_account_id`, groups: `ADMIN`, `PRODUCER` |
| `lambda` | Lambda function + IAM role | GraalVM native image; env vars: `DYNAMO_TABLE`, `COGNITO_ISSUER_URL`, `COGNITO_CLIENT_ID`, `INSTANCE_NAME`, `INSTANCE_API_URL` |
| `api_gateway` | HTTP API V2 | Single route `POST /v1/sync` + `ANY /{proxy+}` for public endpoints; JWT authorizer pointing at Cognito |
| `storage` | S3 bucket | Lambda deployment artifact |

---

## Definition of Done (infra changes)

- [ ] `terraform fmt` passes on all modified files
- [ ] `terraform validate` passes
- [ ] `terraform plan` output reviewed and attached to the PR
- [ ] No unintended resource replacements or destructions in the plan
- [ ] All new taggable resources carry the required tags
- [ ] `README.md` updated if new variables or outputs are added
