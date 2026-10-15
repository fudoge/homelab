data "terraform_remote_state" "aws" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "aws/terraform.tfstate"
    region = var.region
  }
}

locals {
  # root domain and wildcard domain creates uses identical ACM validation CNAME, so you can pick only one.
  validation = one([
    for dvo in data.terraform_remote_state.aws.outputs.acm_domain_validation_options :
    dvo if dvo.domain_name == "chaewoon.work"
  ])
  heartbeat_api_domain_name = data.terraform_remote_state.aws.outputs.heartbeat_api_domain_name
}

resource "cloudflare_dns_record" "minecraft_dns_srv_record" {
  zone_id = var.zone_id
  name    = var.mc_srv_name
  ttl     = 1
  type    = "SRV"
  proxied = false
  comment = "SRV Record for minecraft"
  data = {
    priority = 0
    weight   = 0
    port     = 25565
    target   = var.mc_target
  }
}

resource "cloudflare_dns_record" "blog" {
  zone_id = var.zone_id
  name    = "blog"
  content = "${var.gh_username}.github.io"
  ttl     = 1
  type    = "CNAME"
  proxied = true
  comment = "Hugo blog Custom Domain"
}

resource "cloudflare_ruleset" "blog_redirect" {
  zone_id     = var.zone_id
  name        = "blog redirects"
  description = "Single blog redirects managed by Terraform"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [
    {
      ref         = "blog_root_to_ko"
      description = "Redirect blog root to Korean homepage"
      expression  = "(http.host eq \"blog.${var.domain}\" and http.request.uri.path eq \"/\")"

      action  = "redirect"
      enabled = true

      action_parameters = {
        from_value = {
          status_code           = 301
          preserve_query_string = true

          target_url = {
            value = "https://blog.${var.domain}/ko/"
          }
        }
      }
    }
  ]
}

resource "cloudflare_dns_record" "acm" {
  zone_id = var.zone_id
  name    = trimsuffix(local.validation.resource_record_name, ".")
  content = trimsuffix(local.validation.resource_record_value, ".")
  type    = "CNAME"
  ttl     = 60
  proxied = false
  comment = "AWS ACM validation record"
}

resource "cloudflare_dns_record" "heartbeat" {
  zone_id = var.zone_id
  name    = "heartbeat"
  content = local.heartbeat_api_domain_name
  ttl     = 1
  type    = "CNAME"
  proxied = false
  comment = "Homelab heartbeat API Gateway domain name"
}

resource "cloudflare_r2_bucket" "public_bucket" {
  provider      = cloudflare.r2
  name          = "public-deploy"
  account_id    = var.account_id
  storage_class = "Standard"
}

resource "cloudflare_r2_custom_domain" "public_bucket_custom_domain" {
  provider    = cloudflare.r2
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.public_bucket.name
  domain      = "assets.chaewoon.work"
  enabled     = true
  zone_id     = var.zone_id
  min_tls     = "1.3"
}
