resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.node_name
  vm_id     = var.vm_id
  clone {
    vm_id = var.template_id
  }

  # True when qemu-guest-agent is ready
  agent {
    enabled = false
  }
  stop_on_destroy = true

  cpu {
    cores = var.cpu_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.disk_size
  }

  dynamic "network_device" {
    for_each = var.networks
    content {
      bridge = network_device.value.bridge
    }
  }

  initialization {
    datastore_id      = var.datastore_id
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id

    dynamic "ip_config" {
      for_each = var.networks
      content {
        ipv4 {
          address = ip_config.value.ip
          gateway = ip_config.value.gw != "" ? ip_config.value.gw : null
        }
      }
    }
  }
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  node_name    = var.node_name
  datastore_id = var.datastore_id
  content_type = "snippets"

  source_raw {
    data      = var.cloud_init_data
    file_name = "${var.vm_name}.cloud-config.yaml"
  }
}
