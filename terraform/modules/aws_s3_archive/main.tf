// S3 bucket
resource "aws_s3_bucket" "backup_bucket" {
  bucket = var.backup_bucket_name

  tags = {
    Name = var.backup_bucket_name
  }

}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup_bucket_sse_conf" {
  bucket = aws_s3_bucket.backup_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backup_bucket_public_acls" {
  bucket                  = aws_s3_bucket.backup_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backup_bucket_lifecycle" {
  bucket = aws_s3_bucket.backup_bucket.id

  rule {
    id     = "move-to-glacier"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.transition_days_to_archive
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.expiration_days
    }
  }
}

data "aws_iam_policy_document" "backup_bucket_policy" {
  statement {
    sid    = "AllowBackupUsersObjectRW"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.backup_users
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    resources = [
      "${aws_s3_bucket.backup_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "AllowReadonlyUsersRead"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.readonly_users
    }

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.backup_bucket.arn,
      "${aws_s3_bucket.backup_bucket.arn}/*",
    ]
  }

  statement {
    sid    = "DenyOthersListBucket"
    effect = "Deny"

    not_principals {
      type        = "AWS"
      identifiers = concat(var.backup_users, var.readonly_users)
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.backup_bucket.arn
    ]
  }

  statement {
    sid    = "DenyOthersObjectAccess"
    effect = "Deny"

    not_principals {
      type        = "AWS"
      identifiers = concat(var.backup_users, var.readonly_users)
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]

    resources = [
      "${aws_s3_bucket.backup_bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "backup_bucket_policy" {
  bucket = aws_s3_bucket.backup_bucket.id
  policy = data.aws_iam_policy_document.backup_bucket_policy.json
}
