locals {
  backup_buckets = {
    "vw-backup" = {
      bucket_name                = "riveroverflow-vaultwarden-backup"
      transition_days_to_archive = 2
      expiration_days            = 180
    },
    "mc-backup" = {
      bucket_name                = "riveroverflow-minecraft-backup"
      transition_days_to_archive = 15
      expiration_days            = 180
    }
  }

  backup_bucket_arns = [
    for m in module.backup_s3_buckets : m.bucket_arn
  ]
  backup_bucket_resources = [
    for m in module.backup_s3_buckets : "${m.bucket_arn}/*"
  ]
}

// backup-bucket
module "backup_s3_buckets" {
  source                     = "../../modules/aws_s3_archive"
  for_each                   = local.backup_buckets
  backup_bucket_name         = each.value.bucket_name
  transition_days_to_archive = each.value.transition_days_to_archive
  expiration_days            = each.value.expiration_days
  backup_users               = [aws_iam_user.backup_usr.arn]
  readonly_users             = ["arn:aws:iam::647502392199:user/chaewoon"]
}

// SNS
resource "aws_sns_topic" "email_notifications" {
  name              = "noti-on-backup-failure-topic"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "admin_email_subscription" {
  topic_arn = aws_sns_topic.email_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

// IAM user to backup
resource "aws_iam_user" "backup_usr" {
  name = "archive-backup-usr"
  path = "/"

  tags = {
    Purpose   = "backup"
    Service   = "backup_archives"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "backup_min" {
  statement {
    sid       = "S3ListBucketForPrefix"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = local.backup_bucket_arns

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["*"]
    }
  }

  statement {
    sid       = "S3ListBucketMultipartUploads"
    actions   = ["s3:ListBucketMultipartUploads"]
    resources = local.backup_bucket_arns
  }

  statement {
    sid = "S3ObjectCpOnly"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = local.backup_bucket_resources
  }

  statement {
    sid       = "SnsPublishOnly"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.email_notifications.arn]
  }
}

resource "aws_iam_policy" "backup_min" {
  name   = "backup-minimal"
  policy = data.aws_iam_policy_document.backup_min.json
}

resource "aws_iam_user_policy_attachment" "backup_attach" {
  user       = aws_iam_user.backup_usr.name
  policy_arn = aws_iam_policy.backup_min.arn
}
