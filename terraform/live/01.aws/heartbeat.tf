locals {
  route_key = "POST /api/heartbeat"
}

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
  name                         = "heartbeat"
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = true
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
  route_key = local.route_key

  target = "integrations/${aws_apigatewayv2_integration.heartbeat.id}"
}

resource "aws_apigatewayv2_stage" "heartbeat" {
  api_id      = aws_apigatewayv2_api.heartbeat.id
  name        = "homelab"
  auto_deploy = true

  route_settings {
    route_key              = local.route_key
    throttling_burst_limit = 3
    throttling_rate_limit  = 0.05
  }
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
