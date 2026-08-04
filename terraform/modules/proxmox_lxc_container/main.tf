resource "proxmox_virtual_environment_container" "container" {
  description = var.description

  node_name = var.node_name
  vm_id     = var.vm_id

  unprivileged = true
  protection   = var.protection

  features {
    nesting = true
  }

  device_passthrough {
    path = "/dev/net/tun"
  }

  cpu {
    cores = 2
    limit = 2
    units = 1024
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys     = var.ssh_keys
      password = random_password.container.result
    }
  }

  wait_for_ip {
    ipv4 = true
  }

  network_interface {
    name = var.network_interface
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size
  }

  operating_system {
    template_file_id = var.template_file_id
    type             = var.os_type
  }

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  dynamic "mount_point" {
    for_each = var.mount_points

    content {
      path   = mount_point.value.path
      volume = mount_point.value.volume

      size          = try(mount_point.value.size, null)
      read_only     = try(mount_point.value.read_only, null)
      backup        = try(mount_point.value.backup, null)
      replicate     = try(mount_point.value.replicate, null)
      shared        = try(mount_point.value.shared, null)
      quota         = try(mount_point.value.quota, null)
      acl           = try(mount_point.value.acl, null)
      mount_options = try(mount_point.value.mount_options, null)
    }
  }

  tags = var.tags
}

resource "random_password" "container" {
  length           = 16
  override_special = "_%@"
  special          = true
}

output "container_password" {
  value     = random_password.container.result
  sensitive = true
}
