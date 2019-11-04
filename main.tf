terraform {
  required_version = ">= 0.12"
}

locals {
  name_lower      = lower("${var.project}-${var.environment}-${var.bucket_name}")
  name_logs_lower = "${local.name_lower}-logs"
  tags = merge(
    {
      project     = var.project
      environment = var.environment
    },
    var.tags
  )

  s3_origin_id = "S3-${aws_s3_bucket.website_bucket.id}"
}

# Update bucket policy

data "aws_iam_policy_document" "website_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website_bucket.arn}/*"]

    principals {
      // more info at https://github.com/terraform-providers/terraform-provider-aws/issues/10158
      type = "CanonicalUser"
      // identifiers = [replace(aws_cloudfront_origin_access_identity.website_bucket.iam_arn, " ", "_")]
      identifiers = [aws_cloudfront_origin_access_identity.website_bucket.s3_canonical_user_id]
    }
  }
}

resource "aws_s3_bucket_policy" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.website_bucket.json

  lifecycle {
    ignore_changes = [policy]
  }
}

# Configure access identity

resource "aws_cloudfront_origin_access_identity" "website_bucket" {
  comment = local.s3_origin_id

  // to avoid: Error deleting S3 policy: OperationAborted: A conflicting conditional operation is currently in progress against this resource. Please try again.
  depends_on = [aws_s3_bucket_public_access_block.website_bucket]
}

# Bucket receiving logs from static web hosting bucket

resource "aws_kms_key" "log_bucket" {
  count                   = var.manage_log_bucket ? 1 : 0
  description             = "Used to encrypt objects in the S3 Bucket: ${local.name_logs_lower}"
  deletion_window_in_days = 7

  policy = templatefile("${path.module}/templates/log-bucket-kms-key-policy.json.tpl", {
    account_id = data.aws_caller_identity.current.account_id
    region     = data.aws_region.current.name
  })

  tags = merge({ Name = local.name_logs_lower }, local.tags)
}

resource "aws_kms_alias" "log_bucket" {
  count         = var.manage_log_bucket ? 1 : 0
  name          = "alias/${local.name_logs_lower}"
  target_key_id = aws_kms_key.log_bucket[0].key_id
}

resource "aws_s3_bucket" "log_bucket" {
  count  = var.manage_log_bucket ? 1 : 0
  bucket = local.name_logs_lower
  acl    = "log-delivery-write"

  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.log_bucket[0].arn
      }
    }
  }

  tags = merge({ Name = local.name_logs_lower }, local.tags)
}

resource "aws_s3_bucket_public_access_block" "block_public_access_log_bucket" {
  count  = var.manage_log_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## Bucket for static website hosting

resource "aws_s3_bucket" "website_bucket" {
  bucket = local.name_lower
  acl    = "private"

  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  dynamic "logging" {
    for_each = var.manage_log_bucket ? [1] : []
    content {
      target_bucket = aws_s3_bucket.log_bucket[0].id
      target_prefix = var.logging_prefix
    }
  }

  tags = merge({ Name = local.name_lower }, local.tags)
}

resource "aws_s3_bucket_public_access_block" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure the credentials and access to the bucket for a deployment user

resource "aws_iam_policy" "site_deployer_policy" {
  name        = "${local.name_lower}-deployer"
  path        = "/"
  description = "Policy allowing to publish a new version of the website to the S3 bucket"
  policy = templatefile("${path.module}/templates/deployer_role_policy.json", {
    bucket = local.name_lower
  })
}

resource "aws_iam_policy_attachment" "site_deployer_attach_user_policy" {
  count      = length(var.deployer_users)
  name       = "${local.name_lower}-deployer-policy-attachment"
  users      = var.deployer_users
  policy_arn = aws_iam_policy.site_deployer_policy.arn
}

resource "aws_iam_policy_attachment" "site_deployer_attach_group_policy" {
  count      = length(var.deployer_groups)
  name       = "${local.name_lower}-deployer-policy-attachment"
  users      = var.deployer_groups
  policy_arn = aws_iam_policy.site_deployer_policy.arn
}
