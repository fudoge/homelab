provider "aws" {
  region = var.region

  default_tags {
    tags = {
      ManagedBy  = "OpenTofu"
      Repository = "fudoge/homelab"
    }
  }
}
