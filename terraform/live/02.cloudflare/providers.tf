provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "cloudflare" {
  alias     = "r2"
  api_token = var.cloudflare_r2_api_token
}
