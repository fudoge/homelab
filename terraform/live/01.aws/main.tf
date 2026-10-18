data "terraform_remote_state" "cloudflare" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "cloudflare/terraform.tfstate"
    region = var.region
  }
}

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

#######
# ACM #
#######
resource "aws_acm_certificate" "cert" {
  domain_name               = "chaewoon.work"
  validation_method         = "DNS"
  subject_alternative_names = ["*.chaewoon.work", "chaewoon.work"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn

  validation_record_fqdns = [
    data.terraform_remote_state.cloudflare.outputs.acm_name
  ]
}

#################
# Backup Bucket #
#################
module "backup_s3_buckets" {
  source                     = "../../modules/aws_s3_archive"
  for_each                   = local.backup_buckets
  backup_bucket_name         = each.value.bucket_name
  transition_days_to_archive = each.value.transition_days_to_archive
  expiration_days            = each.value.expiration_days
  backup_users               = [aws_iam_user.backup_usr.arn]
  readonly_users             = ["arn:aws:iam::647502392199:user/chaewoon"]
}

# SNS
resource "aws_sns_topic" "email_notifications" {
  name              = "noti-on-backup-failure-topic"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "admin_email_subscription" {
  topic_arn = aws_sns_topic.email_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# IAM user to backup
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

#################
# Heartbeat API #
#################

## Lambda
data "aws_iam_policy_document" "heartbeat_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "heartbeat" {
  name               = "${var.heartbeat_func_name}-role"
  assume_role_policy = data.aws_iam_policy_document.heartbeat_assume_role.json
}

data "archive_file" "heartbeat" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/heartbeat/src"
  output_path = "${path.module}/lambda/heartbeat/function.zip"
}

resource "aws_lambda_function" "heartbeat" {
  filename      = data.archive_file.heartbeat.output_path
  function_name = var.heartbeat_func_name
  role          = aws_iam_role.heartbeat.arn
  handler       = "lambda_function.lambda_handler"
  code_sha256   = data.archive_file.heartbeat.output_base64sha256

  runtime = "python3.14"

  environment {
    variables = {
      HEARTBEAT_TOKEN_SHA256 = var.heartbeat_token
      HEARTBEAT_NAMESPACE    = var.cloudwatch_heartbeat_ns
    }
  }
}


data "aws_iam_policy_document" "heartbeat_put_metric_data" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"

      values = [
        var.cloudwatch_heartbeat_ns
      ]
    }
  }
}

resource "aws_iam_policy" "heartbeat_put_metric_data" {
  name   = "${var.heartbeat_func_name}-put-metric-data"
  path   = "/"
  policy = data.aws_iam_policy_document.heartbeat_put_metric_data.json
}

resource "aws_iam_role_policy_attachment" "heartbeat_put_metric_data" {
  role       = aws_iam_role.heartbeat.name
  policy_arn = aws_iam_policy.heartbeat_put_metric_data.arn
}

resource "aws_iam_role_policy_attachment" "heartbeat_cloudwatch_logs" {
  role       = aws_iam_role.heartbeat.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "heartbeat" {
  name              = "/aws/lambda/${var.heartbeat_func_name}"
  retention_in_days = 1
}

## API Gateway
resource "aws_apigatewayv2_api" "heartbeat" {
  name          = "heartbeat"
  protocol_type = "HTTP"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowHeartbeatAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.heartbeat.function_name
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_apigatewayv2_api.heartbeat.execution_arn}/*"
}

resource "aws_apigatewayv2_integration" "heartbeat" {
  api_id           = aws_apigatewayv2_api.heartbeat.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.heartbeat.invoke_arn
}

resource "aws_apigatewayv2_route" "heartbeat" {
  api_id    = aws_apigatewayv2_api.heartbeat.id
  route_key = "POST /api/heartbeat"

  target = "integrations/${aws_apigatewayv2_integration.heartbeat.id}"
}

resource "aws_apigatewayv2_stage" "heartbeat" {
  api_id      = aws_apigatewayv2_api.heartbeat.id
  name        = "homelab"
  auto_deploy = true
}

resource "aws_apigatewayv2_domain_name" "heartbeat" {
  domain_name = "heartbeat.chaewoon.work"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "heartbeat" {
  api_id      = aws_apigatewayv2_api.heartbeat.id
  domain_name = aws_apigatewayv2_domain_name.heartbeat.id
  stage       = aws_apigatewayv2_stage.heartbeat.id
}
