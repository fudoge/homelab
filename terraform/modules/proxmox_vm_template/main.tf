resource "proxmox_virtual_environment_vm" "template" {
  name      = var.template_name
  node_name = var.ve_node_name
  vm_id     = var.template_id

  template = true # Template
  started  = false

  machine     = "q35"  # modern vm type <-> pc: legacy system
  bios        = "ovmf" # UEFI
  description = "Managed by Terraform"

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  # Required if bios == ovmf
  efi_disk {
    datastore_id = var.datastore_id
    type         = "4m" # Recommended
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = proxmox_download_file.cloud_image.id # file ID for a disk image
    interface    = "virtio0"
    iothread     = true
    discard      = "on" # pass discard/trim requests to the underlying storage
    size         = 20
  }

  # Cloud_init config
  initialization {
    datastore_id = var.datastore_id
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}

# Download Cloud image
resource "proxmox_download_file" "cloud_image" {
  content_type = "iso"
  datastore_id = var.datastore_id
  node_name    = var.ve_node_name
  url          = var.image_url

  upload_timeout = 3600
}
