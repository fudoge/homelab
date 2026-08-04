resource "proxmox_network_linux_bridge" "vmbr1" {
  node_name = "pve-01"
  name      = "vmbr1"
  comment   = "In-proxmox network"
}
