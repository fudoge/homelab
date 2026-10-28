data "terraform_remote_state" "cloudflare" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "cloudflare/terraform.tfstate"
    region = var.region
  }
}

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
