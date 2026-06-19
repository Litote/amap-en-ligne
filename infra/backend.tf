terraform {
  # Partial backend configuration: the state bucket name embeds the AWS account
  # id, so it is kept out of version control. Provide it at init time via
  # `terraform init -backend-config=backend.hcl` (see backend.hcl.sample).
  # The Makefile `init` target does this automatically.
  backend "s3" {
    key                  = "lambda/terraform.tfstate"
    region               = "eu-west-3"
    encrypt              = true
    use_lockfile         = true
    workspace_key_prefix = "workspaces"
  }
}
