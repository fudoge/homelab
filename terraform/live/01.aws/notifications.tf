data "aws_iam_policy_document" "slack_notify_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "slack_notify" {
  name               = "homelab-slack-notify-role"
  assume_role_policy = data.aws_iam_policy_document.slack_notify_assume_role.json
}

data "aws_iam_policy_document" "slack_notify_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.slack_webhook.arn]
  }
}

resource "aws_iam_role_policy" "slack_notify_secret" {
  name   = "read-slack-webhook"
  role   = aws_iam_role.slack_notify.id
  policy = data.aws_iam_policy_document.slack_notify_secret.json
}

resource "aws_iam_role_policy_attachment" "slack_notify_logs" {
  role       = aws_iam_role.slack_notify.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "slack_notify" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/slack_notify/src"
  output_path = "${path.module}/lambda/slack_notify/function.zip"
}

resource "aws_lambda_function" "heartbeat_slack_notify" {
  filename      = data.archive_file.slack_notify.output_path
  function_name = "homelab-heartbeat-slack-notify"
  role          = aws_iam_role.slack_notify.arn
  handler       = "lambda_function.lambda_handler"
  code_sha256   = data.archive_file.slack_notify.output_base64sha256
  runtime       = "python3.14"
  timeout       = 10

  environment {
    variables = {
      SLACK_WEBHOOK_SECRET_ARN = aws_secretsmanager_secret.slack_webhook.arn
    }
  }
}

resource "aws_cloudwatch_log_group" "heartbeat_slack_notify" {
  name              = "/aws/lambda/${aws_lambda_function.heartbeat_slack_notify.function_name}"
  retention_in_days = 14
}

# Watchdog is configured to publish heartbeats repeatedly. Require three bad
# one-minute periods to avoid paging on a brief delivery gap. CloudWatch can
# look farther back for real points, so detection is not exactly three minutes.
resource "aws_cloudwatch_metric_alarm" "heartbeat_missing" {
  alarm_name          = "homelab-heartbeat-missing"
  alarm_description   = "Alertmanager Watchdog heartbeat has stopped reaching CloudWatch"
  namespace           = var.cloudwatch_heartbeat_ns
  metric_name         = "Heartbeat"
  statistic           = "Sum"
  unit                = "Count"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  # Alarm actions fire on state transitions. One healthy point is enough to
  # leave ALARM with the 3-of-3 rule, so send that recovery transition too.
  alarm_actions = [aws_lambda_function.heartbeat_slack_notify.arn]
  ok_actions    = [aws_lambda_function.heartbeat_slack_notify.arn]
}

# CloudWatch invokes Lambda directly; this permission is limited to this alarm.
resource "aws_lambda_permission" "heartbeat_alarm_invoke" {
  statement_id  = "AllowHeartbeatAlarmInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.heartbeat_slack_notify.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.heartbeat_missing.arn
}
