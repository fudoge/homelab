provider "proxmox" {
  endpoint = "https://pve-01.tail274d3c.ts.net:8006"
  username = var.proxmox_username
  password = var.proxmox_password

  ssh {
    agent               = true
    node_address_source = "dns"
    username            = "root"
  }
}
