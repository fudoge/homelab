terraform {
  required_version = "~> 1.12.5"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
  }
}
