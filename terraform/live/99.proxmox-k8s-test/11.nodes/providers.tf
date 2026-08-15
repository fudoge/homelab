provider "proxmox" {
  endpoint  = "https://pve-01.tail274d3c.ts.net:8006"
  api_token = var.proxmox_api_token

  ssh {
    agent               = true
    node_address_source = "dns"
    username            = "root"
  }
}
