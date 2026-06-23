terraform {
  required_version = "~> 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.50"
    }
  }
  # Intentional local state — this bootstrap folder must never be deleted
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project   = "amap-en-ligne"
      ManagedBy = "terraform-bootstrap"
    }
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "amap-en-ligne"
}

data "aws_caller_identity" "current" {}

# ─── S3 bucket for the state ─────────────────────────────────────────────────

resource "aws_s3_bucket" "tfstate" {
  bucket        = "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ─── DynamoDB table for the lock ─────────────────────────────────────────────

resource "aws_dynamodb_table" "tflock" {
  name         = "${var.project}-tflock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}

# ─── Outputs ──────────────────────────────────────────────────────────────────

output "state_bucket_name" {
  description = "S3 bucket name for the Terraform state"
  value       = aws_s3_bucket.tfstate.id
}

output "lock_table_name" {
  description = "DynamoDB table name for the lock"
  value       = aws_dynamodb_table.tflock.name
}

