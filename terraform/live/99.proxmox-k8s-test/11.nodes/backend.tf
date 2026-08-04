terraform {
  backend "s3" {
    bucket       = var.state_bucket_name
    key          = "proxmox/k8s-test/nodes/terraform.tfstate"
    region       = var.region
    encrypt      = true
    use_lockfile = true
  }
}
