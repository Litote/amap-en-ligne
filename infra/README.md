# Infrastructure — amap-en-ligne

Deployment of `DataLambda` on AWS via Terraform.

- **Runtime**: GraalVM native image on AWS Lambda custom runtime (`provided.al2023`)
- **API**: API Gateway HTTP v2 with native JWT authorizer
- **Envs**: Terraform workspaces (`dev` / `prod`)

---

## Why a Makefile (and not Gradle)?

The repository's build is orchestrated by Gradle (`back`, `front`, `convention` composite
build). This `Makefile` is **not** a second build tool — it is the infra/deployment
orchestrator, and the split is intentional:

- It only *calls* Gradle for the build (`./back/gradlew … packageNative / tracing /
  metadataCopy`), wrapped in a `docker run` GraalVM container to produce a `linux/amd64`
  native image regardless of host OS. Everything else it does is **Terraform** (workspace
  selection, `init -backend-config=backend.hcl`, interactive `apply`/`destroy`) and
  **AWS CLI** (`flutter build web`, `aws s3 sync`, CloudFront invalidation, maintenance
  page) — none of which is Gradle-shaped.
- The Gradle composite build deliberately excludes `infra/`. Folding these targets into
  Gradle `Exec` tasks would add indirection and risk (a Gradle task launching Docker that
  launches Gradle is circular) without simplifying anything.
- **CI does not use this Makefile.** `.github/workflows/deploy-lambda.yml` and `back-ci.yml`
  call `gradlew`, `terraform`, and `aws` directly. The Makefile is purely local-developer
  convenience.

---

## Prerequisites

Install the following tools:

| Tool | Version |
|------|---------|
| Java | 25+ |
| Gradle | via wrapper |
| Docker | recent |
| Terraform | ~> 1.11 |
| AWS CLI | v2 |

---

## 1. Bootstrap (once per AWS account)

Bootstrap creates:
- the S3 bucket for Terraform state (AES256 server-side encryption)
- the IAM policy and `amap-en-ligne-deployer` group for subsequent deployments
- the GitHub Actions **OIDC provider** + the `github-actions-deploy-lambda` role (used by
  the CI deploy — see *Continuous deployment* below; `bootstrap/github_oidc.tf`)
- a legacy DynamoDB lock table kept only for backward compatibility with older
  Terraform S3 backend locking setups

### Before running bootstrap

Bootstrap must be run **once by an AWS admin account** (or a user with broad S3, DynamoDB, and IAM permissions). This is the only moment admin rights are required — subsequent deployments use the restricted policy created by bootstrap.

Checklist before running:

- [ ] **AWS account available** with console or API access
- [ ] **Credentials configured** for an admin user/role:
  ```bash
  aws configure
  # or
  export AWS_PROFILE=my-admin-profile
  # Verify:
  aws sts get-caller-identity
  ```
- [ ] **Target region confirmed** (default: `eu-west-3`) — check in `bootstrap/main.tf`

### Running bootstrap

```bash
cd infra
make bootstrap
```

### After bootstrap

Retrieve the S3 bucket name from the output and put it in a local `backend.hcl`
(gitignored — the bucket name embeds the AWS account id, so it is kept out of
version control):

```bash
# infra/backend.hcl  (copy from backend.hcl.sample)
cp backend.hcl.sample backend.hcl
# then edit it:
bucket = "amap-en-ligne-tfstate-123456789012"  # ← bootstrap output
```

`make init` passes this file to Terraform via `terraform init -backend-config=backend.hcl`
(partial backend configuration). The rest of the backend settings stay in `backend.tf`.

The root Terraform backend now uses S3 native lockfiles (`use_lockfile = true`).
The bootstrap DynamoDB lock table remains in place only to ease migration from
older Terraform setups that still relied on `dynamodb_table`.

---

## 2. Sensitive variables

`jwt_issuer_url` and `jwt_audience` must **never** be committed.

**Option A** — environment variables (CI/CD):
```bash
export TF_VAR_jwt_issuer_url="https://cognito-idp.eu-west-3.amazonaws.com/eu-west-3_XXXXX"
export TF_VAR_jwt_audience="my-client-id"
```

**Option B** — local file ignored by git:
```bash
# infra/secrets.auto.tfvars  (in .gitignore)
jwt_issuer_url = "https://..."
jwt_audience   = "..."
```

### Push notifications (SNS Mobile Push — ADR-005)

Mobile push for the Lambda deployment uses SNS Platform Applications, created by the
`push` module. Each platform is enabled only when its credentials are supplied (so push can
be rolled out per platform); leave them empty to keep push disabled. Supply secrets via the
environment, never via a committed tfvars:

```bash
# Android (FCM HTTP v1 service-account JSON)
export TF_VAR_fcm_service_account_json="$(cat service-account.json)"

# iOS (APNs token-based .p8)
export TF_VAR_apns_signing_key="$(cat AuthKey_XXXX.p8)"
export TF_VAR_apns_signing_key_id="ABC123DEFG"
export TF_VAR_apns_team_id="TEAM123456"
export TF_VAR_apns_bundle_id="org.amap-en-ligne.app"
export TF_VAR_apns_sandbox="false"   # true for development builds
```

The resulting platform-application ARNs are injected into the Lambda as
`SNS_PLATFORM_APP_ARN_ANDROID` / `SNS_PLATFORM_APP_ARN_IOS` (consumed by
`SnsPushNotificationChannelSender`) and exposed as the
`push_android_platform_application_arn` / `push_ios_platform_application_arn` outputs. The
Lambda role gains `sns:CreatePlatformEndpoint` / `Publish` / `Get`/`SetEndpointAttributes`
/ `DeleteEndpoint` scoped to those applications and their endpoints — only when at least one
platform is configured.

> The JVM deployment uses FCM HTTP v1 directly (no AWS); it is not provisioned here.

---

## 3. Deploy

```bash
cd infra

# Dev
make dev

# Prod
make prod

# Preview the plan before applying
make plan-dev
make plan-prod
```

---

## 3bis. Continuous deployment (GitHub Actions)

`.github/workflows/deploy-lambda.yml` deploys **without the Makefile**, calling
`gradlew` / `terraform` / `aws` directly. It authenticates to AWS through **OIDC**
(no long-lived keys).

### Trigger matrix

| Event | Jobs | Workspace |
|-------|------|-----------|
| **Push to `main`** (paths `back/**`, `infra/**`, the workflow) | `build-native` → `terraform-apply` → `deploy-function` | `dev` |
| **Pull request** | `build-native` → `terraform-plan` (read-only) | `dev` |
| **Manual** (`workflow_dispatch`) | `build-native` → `terraform-apply` → `deploy-function` | `dev` |

`terraform-apply` and `deploy-function` run in the GitHub **`production` environment**,
which is restricted by a *deployment branch policy* to `main` — so a deploy can only
originate from `main`, even via `workflow_dispatch`.

### AWS OIDC role (codified in `bootstrap/github_oidc.tf`)

The workflow assumes `github-actions-deploy-lambda` via the GitHub OIDC provider. Its
trust policy only accepts two token subjects of this repository:

- `repo:<owner>/<repo>:environment:production` — the deploy jobs (gated to `main` by the
  environment branch policy above)
- `repo:<owner>/<repo>:pull_request` — the read-only plan job

The role carries the `amap-en-ligne-deployer-policy` (same as the CI group). The OIDC
provider, the role and its trust policy are **managed by `bootstrap/`** — apply the
bootstrap to create/update them:

```bash
cd infra/bootstrap && terraform apply
```

> The `github_repo` variable (default in `github_oidc.tf`) must match the GitHub
> repository running the workflow. After a repo rename/transfer, update it and re-apply
> the bootstrap, otherwise OIDC fails with `Not authorized to perform
> sts:AssumeRoleWithWebIdentity`.

### Required GitHub configuration

Actions **variables** (`gh variable set …`):

| Name | Example | Purpose |
|------|---------|---------|
| `AWS_REGION` | `eu-west-3` | Deployment region |
| `TF_STATE_BUCKET` | `amap-en-ligne-tfstate-<account_id>` | Terraform S3 backend bucket |
| `AWS_LAMBDA_FUNCTION_NAME` | `amap-en-ligne-dev` | Target of `deploy-function` |
| `INSTANCE_API_URL` | `https://<id>.cloudfront.net` | Public API base (Cognito callback/logout + discovery). **No trailing slash** |

Actions **secrets** (`gh secret set …`):

| Name | Maps to | Notes |
|------|---------|-------|
| `AWS_ROLE_ARN` | role to assume | ARN of `github-actions-deploy-lambda` |
| `GRADLE_ENCRYPTION_KEY` | Gradle cache | native build |
| `TF_VAR_COGNITO_CLIENT_ID` | `var.cognito_client_id` | |
| `TF_VAR_INITIAL_OWNER_EMAIL` | `var.initial_owner_email` | bootstrap owner |
| `TF_VAR_INITIAL_OWNER_TEMP_PASSWORD` | `var.initial_owner_temp_password` | schema-validated only (≥12 chars, upper/lower/digit); ignored on the existing user via `ignore_changes = [password]` |
| `TF_VAR_SES_FROM_EMAIL` | `var.ses_from_email` | SES sender identity |

> **Why all these `TF_VAR_*`?** Several resources use `count = var.x != "" ? 1 : 0`
> (initial owner, SES identity, discovery server item). If the CI apply does **not**
> supply a variable the existing state was built with, that resource flips to `count = 0`
> and Terraform **destroys** it (and `prevent_destroy` ones hard-fail the apply). The CI
> must therefore pass the **same** variable set the deploy was first created with.

### First-time CI setup checklist

1. `cd infra/bootstrap && terraform apply` — creates the OIDC provider + role + deployer
   policy (admin credentials, once per account).
2. Create the GitHub variables and secrets above.
3. In repo **Settings → Environments**, create `production` and set its *deployment branch
   policy* to `main` only.
4. Push to `main` (touching `back/**` or `infra/**`) or run the workflow manually.

### Manual production deploy (separate AWS account)

`dev` deploys automatically on push to `main`. **Production is manual-only** and lives in a
**separate AWS account** (so the singleton `data` DynamoDB table never collides between
environments). The same workflow drives it through the `workflow_dispatch` `target` input:

> **Actions → Deploy — Lambda (AWS) → Run workflow → `target: prod`**

The `terraform-apply` / `deploy-function` jobs then resolve their GitHub **environment** to
`prod` (instead of `production`) and select the Terraform **workspace** `prod`. All
`vars`/`secrets` are read from the `prod` environment scope, so they carry the prod
account's values.

One-time prod setup:

1. **In the prod AWS account**, run the bootstrap with admin credentials:
   ```bash
   cd infra/bootstrap && AWS_PROFILE=<prod-admin> terraform apply
   ```
   This creates the prod state bucket, the OIDC provider, the `github-actions-deploy-lambda`
   role and the deployer policy. The role's trust policy already allows the
   `…:environment:prod` subject (see `github_oidc.tf`).
2. **Create the GitHub `prod` environment** (Settings → Environments → `prod`). Recommended
   protection: *required reviewers* + deployment branch policy `main`.
3. **Set the `prod` environment's variables and secrets** — the **same names** as the dev
   table above (`AWS_REGION`, `TF_STATE_BUCKET`, `AWS_LAMBDA_FUNCTION_NAME`,
   `INSTANCE_API_URL`, `AWS_ROLE_ARN`, `TF_VAR_*`, …) but with the **prod account's**
   values (prod role ARN, prod state bucket, prod URL, …).
4. Trigger the workflow manually with `target: prod`.

> The `data` table name is **not** workspace-namespaced (`var.dynamo_table_name` defaults to
> `data`). Running dev and prod in the **same** account would make them share that table —
> which is why prod must be a separate account. If you ever need same-account isolation,
> namespace the table first (a destructive change for the existing dev table).

---

## 4. Test the API

```bash
# Print the URL
make url
# → https://xxxxxxxxxx.execute-api.eu-west-3.amazonaws.com

# Call the sync endpoint
URL=$(make -s url)
curl -X POST "$URL/v1/sync" \
  -H "Authorization: Bearer <your-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"cursors":{}}'
```

---

## 5. Instance customization

The `infra/instance/` directory contains files that are specific to this deployment
and override the generic defaults bundled with the Flutter app.

### `infra/instance/cgu.html` — Terms of service

The app displays a terms-of-service link on every registration form (AMAP join,
organization creation, producer sign-up). By default it falls back to `cgu.html`
served at the web root. The file in `infra/instance/cgu.html` replaces that default
for this deployment.

**Edit `infra/instance/cgu.html`** to fill in the `<!-- TODO -->` placeholders
(operator identity, data-retention period, hosting provider, jurisdiction). The file
is committed to the repository — it is intentionally instance-specific and not a
template.

#### Lambda deployment (S3 + CloudFront)

`terraform apply` uploads `infra/instance/cgu.html` to the web S3 bucket as an
`aws_s3_object`. The `deploy-web-dev/prod` Makefile targets exclude `cgu.html` from
`aws s3 sync --delete` so the Terraform-managed version is never overwritten by the
Flutter build.

Update the CGU:
```bash
# Edit infra/instance/cgu.html, then:
cd infra
make dev          # or make prod — terraform apply uploads the new file
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/cgu.html"
```

#### JVM deployment (nginx + docker-compose)

The `nginx` service in `docker-compose.yml` (profile `web`) mounts
`infra/instance/cgu.html` directly over the Flutter build's bundled default.
No extra step needed — restart the nginx container after editing the file:

```bash
docker compose -f back/deploy/jvm/docker-compose.yml --profile web restart nginx
```

#### `INSTANCE_TERMS_URL` (optional override)

Both deployments read the optional `INSTANCE_TERMS_URL` env var. When set, its
value is published in `GET /.well-known/amap-en-ligne.json` as `terms_url` and the
app navigates to that URL directly instead of the local fallback.

Use this when your instance's CGU is already hosted on an external website and you
do not want to maintain a separate copy in `infra/instance/cgu.html`:

- **Lambda**: set `instance_terms_url` in `terraform.tfvars`; the URL is
  auto-derived from `domain_name` (`https://<domain>/cgu.html`) when neither
  is explicitly set.
- **JVM**: uncomment `INSTANCE_TERMS_URL` in `back/deploy/jvm/.env`.

---

## 6. CORS configuration

CORS is handled at the API Gateway level via the `cors_allow_origins` variable.
Three states are supported, mirroring the `CORS_ALLOW_ORIGINS` env var of the
JVM deployment:

| `cors_allow_origins` value           | Effect on API Gateway                                | When to use                                          |
|--------------------------------------|------------------------------------------------------|------------------------------------------------------|
| `[]` (default)                       | No `cors_configuration` block emitted, CORS off      | Production with web client served on the same domain |
| `["*"]`                              | `allow_origins = ["*"]`, wide open                   | Dev only — never deploy this to prod                 |
| `["https://app.example", ...]`       | Explicit whitelist                                   | Cross-origin prod (e.g. federation, separate web host) |

The value lives in `terraform.tfvars` (or any other `.tfvars` you pass). The
default in code is the empty list so a fresh deploy is closed by default.

When you flip the value, `terraform plan` shows the `cors_configuration` block
being added/removed on `aws_apigatewayv2_api.main`. This is a non-destructive
change to the API itself — only the CORS handling at the gateway changes.

---

## Architecture

```
API Gateway HTTP v2
  └── JWT Authorizer (validates the token before reaching the Lambda)
      └── POST /v1/sync
              └── Lambda Integration (payload format 2.0)
                      └── DataLambda (GraalVM native, custom runtime provided.al2023)
                              ├── alias "live" → published version
                              └── Koin DI (DataModule + AuthenticationModule + HttpModule)
```

### GraalVM native image

The Lambda runs as an AOT-compiled GraalVM native image packaged as a custom
runtime ZIP (`bootstrap` executable). Cold starts are sub-second without
needing SnapStart.

- The `live` alias always points to the latest published version.
- `terraform apply` automatically publishes a new version when the ZIP changes.
- The native image is built inside a Docker container pinned to
  `ghcr.io/graalvm/native-image-community:25` so builds are reproducible
  regardless of the host OS.

### Terraform structure

```
infra/
├── bootstrap/          ← State bucket + DynamoDB lock (run once)
├── modules/
│   ├── storage/        ← S3 bucket for the Lambda ZIP (private, encrypted, versioned)
│   ├── lambda/         ← Lambda + IAM + CloudWatch + alias
│   ├── push/           ← SNS Mobile Push platform applications (FCM / APNs, optional)
│   └── api_gateway/    ← HTTP API v2 + JWT authorizer + routes + throttling
├── Makefile            ← Deployment commands
└── README.md
```

---

## Security

| Resource | Measure |
|----------|---------|
| Lambda IAM role | `AWSLambdaBasicExecutionRole` only (CloudWatch logs) |
| Environment variables | Encrypted at rest via AWS-managed key |
| CloudWatch logs | Encrypted at rest via AWS-managed key, 14-day retention |
| S3 artifacts | Private, AES256, versioning, public access blocked |
| Terraform state | AES256-encrypted S3 + native S3 lockfile |
| API Gateway | Throttling (50 req/s, burst 100), access logs |
| JWT | Validated by API Gateway before reaching the Lambda |
| Lambda alias | Invocation routed via `live` alias, never `$LATEST` |

> **Encryption trade-offs**: environment variables and logs use AWS-managed keys (free) instead of Customer Managed Keys ($1/month each). The practical difference: no cryptographic erasure, no key-level CloudTrail audit, no emergency key disable. For secrets (API keys, credentials), use AWS Secrets Manager — never Lambda environment variables.

---

## IAM permissions required for deployment

The group/role running `terraform apply` needs the permissions below. The IAM policy is created automatically by bootstrap (`infra/bootstrap/deployer.tf`) and attached to the `amap-en-ligne-deployer` group.

```bash
# Create the policy and group (included in make bootstrap)
cd infra/bootstrap && terraform apply
```

### Permissions by service

| Service | Actions | Scope |
|---------|---------|-------|
| **STS** | `GetCallerIdentity` | `*` |
| **S3** | Full bucket + object management (`s3:*`) | Buckets `amap-en-ligne-*` (artifacts, web, tfstate) |
| **DynamoDB** | CRUD app table (+ GSIs, PITR, TTL) and legacy lock table | Table `amap-en-ligne-tflock` + `data` (+ `/index/*`) |
| **CloudWatch Logs** | Create/delete log groups, retention | Log groups `/aws/lambda/*` and `/aws/apigateway/*` |
| **CloudWatch Logs** | `DescribeLogGroups` + log-delivery API (API GW access logs) | `*` (no resource-level support) |
| **IAM** | Create/manage Lambda roles and policies | `role/*-lambda-role` + `policy/amap-en-ligne-*` |
| **IAM** | `PassRole` to `lambda.amazonaws.com` | Role `*-lambda-role` |
| **Lambda** | Create/manage function, versions, aliases, permissions | Functions `amap-en-ligne-*` |
| **API Gateway v2** | `GET/POST/PUT/PATCH/DELETE` on APIs, sub-resources and tags | `arn:aws:apigateway:*::/apis/*`, `/tags/*` |
| **Cognito** | User pool, client, resource server, domain, groups, bootstrap admin user | `*` |
| **SNS** | Topic + subscription (activation email) and mobile-push platform apps | Topics `amap-en-ligne-*` + platform apps `*` |
| **SESv2** | Sender email identity | `identity/*` |
| **CloudFront** | Distribution, origin access control, response-headers policy | `*` (no resource-level support) |

### Attach the policy to a user or CI role

```bash
# IAM user
aws iam add-user-to-group \
  --user-name my-user \
  --group-name amap-en-ligne-deployer

# CI role (GitHub Actions, GitLab CI, etc.) — attach the policy directly
POLICY_ARN=$(cd infra/bootstrap && terraform output -raw deployer_policy_arn)
aws iam attach-role-policy \
  --role-name my-ci-role \
  --policy-arn "$POLICY_ARN"
```

> **Provider note**: with the pinned AWS provider `~> 6.0`, `terraform validate`
> still emits `hash_key` / `range_key` deprecation warnings on
> `aws_dynamodb_table`. The documented `key_schema` replacement is not accepted
> by this provider line, so those warnings are currently provider-level noise
> rather than an actionable repository change.

---

## Useful commands

```bash
make help          # list all targets
make fmt           # format .tf files
make validate      # validate the Terraform configuration
make url           # API URL (current workspace)
make destroy-dev   # destroy the dev infrastructure
```
