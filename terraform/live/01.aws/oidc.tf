locals {
  oidc_url = "https://oidc.chaewoon.work"
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url = local.oidc_url
  client_id_list = [
    "sts.amazonaws.com"
  ]
}

module "aws_test" {
  source = "../../modules/aws_oidc_iam"

  role_name                 = "home-alertmanager"
  oidc_provider_arn         = aws_iam_openid_connect_provider.oidc.arn
  oidc_issuer_url           = local.oidc_url
  service_account_namespace = "default"
  service_account_name      = "aws-test"
}
