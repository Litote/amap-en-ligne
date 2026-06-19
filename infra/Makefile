ZIP := ../back/deploy/lambda/build/libs/lambda.zip
TF  := terraform

GIT_COMMIT_HASH := $(shell git -C .. rev-parse --short HEAD 2>/dev/null || echo "unknown")

DART_DEFINES := --dart-define=GIT_COMMIT_HASH=$(GIT_COMMIT_HASH) \
  $(if $(wildcard ../front/dart_defines.local.json),--dart-define-from-file=../front/dart_defines.local.json,\
  $(if $(SENTRY_DSN),--dart-define=SENTRY_DSN=$(SENTRY_DSN)) \
  $(if $(SENTRY_AUTH_TOKEN),--dart-define=SENTRY_AUTH_TOKEN=$(SENTRY_AUTH_TOKEN)))

# ─── Build ────────────────────────────────────────────────────────────────────

.PHONY: build
build: gradle-permissions
	docker run --rm \
		--platform linux/amd64 \
		--entrypoint sh \
		--user $(shell id -u):$(shell id -g) \
		-e GRADLE_USER_HOME=/gradle-home \
		-e "GRADLE_OPTS=-Dorg.gradle.native=false" \
		-v "$(CURDIR)/..:/project" \
		-v gradle-native-cache:/gradle-home \
		-w /project \
		ghcr.io/graalvm/native-image-community:25 \
		-c "./back/gradlew --project-dir back/deploy/lambda packageNative --no-daemon --no-build-cache"
	@echo "✓ Lambda ZIP : $(ZIP)"

.PHONY: sync-serializable
sync-serializable:
	python3 ../scripts/sync-serializable-metadata.py

.PHONY: trace-native
trace-native: gradle-permissions
	docker run --rm \
		--platform linux/amd64 \
		--entrypoint sh \
		--user $(shell id -u):$(shell id -g) \
		--add-host=host.docker.internal:host-gateway \
		-e GRADLE_USER_HOME=/gradle-home \
		-e "GRADLE_OPTS=-Dorg.gradle.native=false" \
		-e DYNAMO_LOCAL_ENDPOINT=http://host.docker.internal:8000 \
		-v "$(CURDIR)/..:/project" \
		-v gradle-native-cache:/gradle-home \
		-w /project \
		ghcr.io/graalvm/native-image-community:25 \
		-c "./back/gradlew --project-dir back/deploy/lambda nativeTracingRun --no-daemon --no-build-cache"

.PHONY: trace-check
trace-check: gradle-permissions
	docker run --rm \
		--platform linux/amd64 \
		--entrypoint sh \
		--user $(shell id -u):$(shell id -g) \
		--add-host=host.docker.internal:host-gateway \
		-e GRADLE_USER_HOME=/gradle-home \
		-e "GRADLE_OPTS=-Dorg.gradle.native=false" \
		-e DYNAMO_LOCAL_ENDPOINT=http://host.docker.internal:8000 \
		-v "$(CURDIR)/..:/project" \
		-v gradle-native-cache:/gradle-home \
		-w /project \
		ghcr.io/graalvm/native-image-community:25 \
		-c "./back/gradlew --project-dir back/deploy/lambda tracing --no-daemon --rerun-tasks"
	@echo "✓ TracingRunner executed on plain JVM (no agent)"

.PHONY: trace
trace: gradle-permissions
	docker run --rm \
		--platform linux/amd64 \
		--entrypoint sh \
		--user $(shell id -u):$(shell id -g) \
		--add-host=host.docker.internal:host-gateway \
		-e GRADLE_USER_HOME=/gradle-home \
		-e "GRADLE_OPTS=-Dorg.gradle.native=false" \
		-e DYNAMO_LOCAL_ENDPOINT=http://host.docker.internal:8000 \
		-v "$(CURDIR)/..:/project" \
		-v gradle-native-cache:/gradle-home \
		-w /project \
		ghcr.io/graalvm/native-image-community:25 \
		-c "./back/gradlew --project-dir back/deploy/lambda -Pagent tracing --no-daemon --no-build-cache"
	@echo "✓ Agent output : back/deploy/lambda/build/native/agent-output/tracing/"

.PHONY: trace-copy
trace-copy: gradle-permissions
	docker run --rm \
		--platform linux/amd64 \
		--entrypoint sh \
		--user $(shell id -u):$(shell id -g) \
		-e GRADLE_USER_HOME=/gradle-home \
		-e "GRADLE_OPTS=-Dorg.gradle.native=false" \
		-v "$(CURDIR)/..:/project" \
		-v gradle-native-cache:/gradle-home \
		-w /project \
		ghcr.io/graalvm/native-image-community:25 \
		-c "./back/gradlew --project-dir back/deploy/lambda metadataCopy --no-daemon"
	@echo "✓ Metadata copied to back/deploy/lambda/src/main/resources/META-INF/native-image/"

.PHONY: gradle-permissions
gradle-permissions:
	docker run --rm \
		-v gradle-native-cache:/gradle-home \
		-v "$(CURDIR)/..:/project" \
		alpine sh -c 'for dir in /gradle-home /project/back /project/convention; do if [ -e "$$dir" ]; then chown -R $(shell id -u):$(shell id -g) "$$dir"; fi; done'

# ─── Bootstrap (once per AWS account) ────────────────────────────────────────

.PHONY: bootstrap
bootstrap:
	cd bootstrap && $(TF) init && $(TF) apply
	@echo "⚠️  Put the bucket name shown above into backend.hcl (see backend.hcl.sample)"

# ─── AWS deployments ──────────────────────────────────────────────────────────

.PHONY: init
init:
	$(TF) init -backend-config=backend.hcl

.PHONY: dev-back
dev-back: build init
	$(TF) workspace select -or-create dev
	$(TF) apply -auto-approve -var="zip_path=$(ZIP)"

.PHONY: dev-web
dev-web: init
	$(TF) workspace select -or-create dev
	cd ../front && flutter build web --wasm $(DART_DEFINES)
	aws s3 sync ../front/build/web/ s3://$$($(TF) output -raw web_bucket)/ --delete --exclude "cgu.html"
	aws cloudfront create-invalidation \
	  --distribution-id $$($(TF) output -raw cloudfront_distribution_id) \
	  --paths "/*"

.PHONY: dev
dev: dev-back dev-web
	@echo "✓ Backend + frontend deployed to dev"

.PHONY: prod-back
prod-back: build init
	$(TF) workspace select -or-create prod
	$(TF) apply -var="zip_path=$(ZIP)"

.PHONY: prod-web
prod-web: init
	$(TF) workspace select -or-create prod
	cd ../front && flutter build web --wasm $(DART_DEFINES)
	aws s3 sync ../front/build/web/ s3://$$($(TF) output -raw web_bucket)/ --delete --exclude "cgu.html"
	aws cloudfront create-invalidation \
	  --distribution-id $$($(TF) output -raw cloudfront_distribution_id) \
	  --paths "/*"

.PHONY: prod
prod: prod-back prod-web
	@echo "✓ Backend + frontend deployed to prod"

.PHONY: plan-dev
plan-dev: build
	$(TF) workspace select -or-create dev
	$(TF) plan -var="zip_path=$(ZIP)"

.PHONY: plan-prod
plan-prod: build
	$(TF) workspace select -or-create prod
	$(TF) plan -var="zip_path=$(ZIP)"

.PHONY: destroy-dev
destroy-dev:
	$(TF) workspace select dev
	$(TF) destroy -var="zip_path=$(ZIP)"

# Import an already-existing Cognito owner into Terraform state (run once when
# the user was created outside Terraform or before this bootstrap resource existed).
# Usage: make import-owner EMAIL=owner@example.com
.PHONY: import-owner
import-owner:
	@test -n "$(EMAIL)" || (echo "Usage: make import-owner EMAIL=owner@example.com" && exit 1)
	$(eval POOL_ID := $(shell $(TF) output -raw cognito_user_pool_id))
	$(TF) import 'module.cognito.aws_cognito_user.initial_owner[0]' $(POOL_ID)/$(EMAIL)

# ─── Utilities ───────────────────────────────────────────────────────────────

.PHONY: fmt
fmt:
	$(TF) fmt -recursive

.PHONY: validate
validate:
	$(TF) validate

.PHONY: url
url:
	@$(TF) output -raw api_url

# ─── Maintenance mode ────────────────────────────────────────────────────────
# Replaces index.html with a maintenance page and invalidates CloudFront.
# To restore: run make dev / make prod.

.PHONY: maintenance-on-dev
maintenance-on-dev: init
	$(TF) workspace select -or-create dev
	aws s3 cp maintenance.html s3://$$($(TF) output -raw web_bucket)/index.html
	aws cloudfront create-invalidation \
	  --distribution-id $$($(TF) output -raw cloudfront_distribution_id) \
	  --paths "/*"
	@echo "✓ Maintenance enabled. Restore with: make dev"

.PHONY: maintenance-on-prod
maintenance-on-prod: init
	$(TF) workspace select -or-create prod
	aws s3 cp maintenance.html s3://$$($(TF) output -raw web_bucket)/index.html
	aws cloudfront create-invalidation \
	  --distribution-id $$($(TF) output -raw cloudfront_distribution_id) \
	  --paths "/*"
	@echo "✓ Maintenance enabled. Restore with: make prod"

.PHONY: help
help:
	@echo "Available targets:"
	@echo ""
	@echo "  Build"
	@echo "    build              Build the GraalVM native Lambda ZIP via Docker"
	@echo "    trace-check        Run TracingRunner on plain JVM (sanity check, no agent)"
	@echo "    trace              Run the handler under native-image-agent and record metadata"
	@echo "    trace-copy         Copy captured metadata into src/main/resources/META-INF/native-image/"
	@echo "    trace-native       Compile TracingRunner as a native binary and execute it (reproduces native-image errors)"
	@echo "    sync-serializable  Scan @Serializable classes under back/ and merge their Companion/serializer() entries into reachability-metadata.json"
	@echo ""
	@echo "  AWS"
	@echo "    bootstrap          Create state bucket + DynamoDB lock (once only)"
	@echo "    dev                Build + deploy backend (Lambda) + frontend (web) to dev"
	@echo "    dev-back           Deploy backend (Lambda) to dev only"
	@echo "    dev-web            Deploy frontend (web) to dev only"
	@echo "    prod               Build + deploy backend (Lambda) + frontend (web) to prod"
	@echo "    prod-back          Deploy backend (Lambda) to prod only"
	@echo "    prod-web           Deploy frontend (web) to prod only"
	@echo "    plan-dev           Plan the dev deployment (no apply)"
	@echo "    plan-prod          Plan the prod deployment (no apply)"
	@echo "    destroy-dev        Destroy the dev infrastructure"
	@echo "    url                Print the API URL (current workspace)"
	@echo "    maintenance-on-dev   Enable the maintenance page (dev) — restore: make dev"
	@echo "    maintenance-on-prod  Enable the maintenance page (prod) — restore: make prod"
	@echo ""
	@echo "  Other"
	@echo "    fmt                Format .tf files"
	@echo "    validate           Validate the Terraform configuration"
