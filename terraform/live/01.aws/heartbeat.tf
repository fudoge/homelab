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
      HEARTBEAT_NAMESPACE = var.cloudwatch_heartbeat_ns
      HEARTBEAT_TOPIC_ARN = aws_sns_topic.heartbeat_topic.arn
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

## SNS
# Using AWS-managed key for encryption
resource "aws_sns_topic" "heartbeat_topic" {
  name              = "homelab-heartbeat"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.heartbeat_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.heartbeat.arn

  depends_on = [aws_lambda_permission.allow_sns_heartbeat]
}

resource "aws_lambda_permission" "allow_sns_heartbeat" {
  statement_id  = "AllowHeartbeatLambdaInvokeFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.heartbeat.function_name
  principal     = "sns.amazonaws.com"

  source_arn = aws_sns_topic.heartbeat_topic.arn
}
