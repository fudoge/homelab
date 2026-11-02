data "aws_caller_identity" "current" {}

locals {
  oidc_url = "https://oidc.chaewoon.work"
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url = local.oidc_url
  client_id_list = [
    "sts.amazonaws.com"
  ]
}

## Alertmanager
data "aws_iam_policy_document" "alertmanager" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.heartbeat_topic.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey*", "kms:Decrypt"]
    resources = ["arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*"]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "kms:ResourceAliases"
      values   = ["alias/aws/sns"]
    }
  }
}

resource "aws_iam_policy" "alertmanager" {
  name        = "homelab-alertmanager-publish-sns"
  path        = "/"
  description = "Permit Alertmanager SNS Publish"

  policy = data.aws_iam_policy_document.alertmanager.json
}

module "alertmanager" {
  source = "../../modules/aws_oidc_iam"

  role_name                 = "homelab-alertmanager"
  oidc_provider_arn         = aws_iam_openid_connect_provider.oidc.arn
  oidc_issuer_url           = local.oidc_url
  service_account_namespace = "observability"
  service_account_name      = "kube-prometheus-stack-alertmanager"
  managed_policy_arns       = [aws_iam_policy.alertmanager.arn]
}
