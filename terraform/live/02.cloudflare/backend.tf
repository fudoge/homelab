terraform {
  backend "s3" {
    bucket       = var.state_bucket_name
    key          = "cloudflare/terraform.tfstate"
    region       = var.region
    encrypt      = true
    use_lockfile = true
  }
}
