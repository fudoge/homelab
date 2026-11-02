resource "cloudflare_r2_bucket" "oidc" {
  provider      = cloudflare.r2
  name          = "home-oidc"
  account_id    = var.account_id
  storage_class = "Standard"
}

resource "cloudflare_r2_custom_domain" "oidc_custom_domain" {
  provider    = cloudflare.r2
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.oidc.name
  domain      = "oidc.chaewoon.work"
  enabled     = true
  zone_id     = var.zone_id
  min_tls     = "1.3"
}
