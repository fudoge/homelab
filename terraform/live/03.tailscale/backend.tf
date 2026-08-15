terraform {
  backend "s3" {
    bucket       = var.state_bucket_name
    key          = "tailscale/terraform.tfstate"
    region       = var.region
    encrypt      = true
    use_lockfile = true
  }
}
