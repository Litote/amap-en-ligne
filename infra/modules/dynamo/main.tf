resource "aws_dynamodb_table" "main" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  # Sparse GSI: only Change items carry change_pk, so only those appear in the index.
  attribute {
    name = "change_pk"
    type = "S"
  }

  attribute {
    name = "cursor"
    type = "S"
  }

  # Sparse GSI: only OrganizationRequest items carry organization_name.
  attribute {
    name = "organization_name"
    type = "S"
  }

  # Sparse GSI: only OrganizationRequest items carry admin_email.
  attribute {
    name = "admin_email"
    type = "S"
  }

  global_secondary_index {
    name = "by_cursor"
    key_schema {
      attribute_name = "change_pk"
      key_type       = "HASH"
    }
    key_schema {
      attribute_name = "cursor"
      key_type       = "RANGE"
    }
    projection_type = "ALL"
  }

  global_secondary_index {
    name = "by_organization_name"
    key_schema {
      attribute_name = "organization_name"
      key_type       = "HASH"
    }
    projection_type = "KEYS_ONLY"
  }

  global_secondary_index {
    name = "by_admin_email"
    key_schema {
      attribute_name = "admin_email"
      key_type       = "HASH"
    }
    projection_type = "KEYS_ONLY"
  }

  point_in_time_recovery {
    enabled = var.protection_enabled
  }

  deletion_protection_enabled = var.protection_enabled

  tags = var.tags
}
