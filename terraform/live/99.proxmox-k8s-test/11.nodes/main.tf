data "terraform_remote_state" "templates" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "proxmox/global/templates/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "frr" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "proxmox/k8s-test/routers/terraform.tfstate"
    region = var.region
  }
}

locals {
  cloud_init_templates_dir = "${path.module}/../../50.proxmox-global/99.cloud-init"

  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBWhBJ+7YbdJYnNzvHEpkkS4j9bgVHJRFCSWDZXL6adH6Z9XZylsfe3BU2YeieJekst/Vo/WPCYZTGinEN3yvxYhsKK0mvoA0Lwbhp9ExdnkCmaPpIDECC1l1l9AlBdPneE5H5ZwOsoaS8DooG8K22WBLvhJapKkSP05aIxZn9A2JRzfguptfGoQeJsCWZhsoPZCrwcdNqWDDRQlUsz1b2HvirkVbnlmkggLo+NnWcFb6CybmrXwIpgvi0ptPvdzdeA8rF6flVuvD0ALn6ywOR9lKwVCkBEYETo/7bLqS3sfdHwB4pctDP6bdqlm2ZDz/Q0VIZoqE2j1mZnCh8x6oTSxiIurrstJdQRQeASF+LscvuHn0ypqhccESqrdASZmjDKANm/3NZf74HJ20xkQ80e6Gwv9HsQ0DaglPWk3W/lDMxdySE1Hq1dUm7nq8RgHt3k2UISuoTBkMA1WZIc0485ibPFxqM4jBNATfO4Qjp+92awSBkDC5eNXUP744/feSkt0eY6fbpWFiDeajxRd43IePEtjRWiW7FWgW9uXa8Xj6g2vhBsYoljWJ23cHUPYzOBGK+QGZyPiggj8vkPT12sWoznDqAbo8dNBKtaLxkcRAKlhAX566kdrjY+PDOqF5e5pqo9LZpKpLGUzluJG3GZ94PCgbpnQvKQBeYJvJnjQ== kchawoon@naver.com",
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+XpFW8WRZcu3noIrPVidAyADg52sv/tjlV3OZ+zHHN chaewoon@spaceship"
  ]

  ubuntu_template_id_26_04 = data.terraform_remote_state.templates.outputs.ubuntu_template_id["ubuntu_26_04"]
  frroute_ip               = data.terraform_remote_state.frr.outputs.frr_ip[1]

  k8s_nodes = {
    "cp-1" : {
      vm_name     = "cp-1"
      vm_id       = 1010,
      cpu_cores   = 2
      memory      = 4096
      disk_size   = 100
      extra_disks = []
      networks = [
        { bridge = "vmbr1", ip = "192.168.10.10/24", gw = local.frroute_ip }
      ]
    }
    "worker-1" : {
      vm_name     = "worker-1"
      vm_id       = 1100,
      cpu_cores   = 4
      memory      = 8192
      disk_size   = 100
      extra_disks = []
      networks = [
        { bridge = "vmbr1", ip = "192.168.10.100/24", gw = local.frroute_ip }
      ]
    }
    "worker-2" : {
      vm_name     = "worker-2"
      vm_id       = 1101,
      cpu_cores   = 4
      memory      = 8192
      disk_size   = 100
      extra_disks = []
      networks = [
        { bridge = "vmbr1", ip = "192.168.10.101/24", gw = local.frroute_ip }
      ]
    }
  }
}

module "k8s-node" {
  source       = "../../../modules/proxmox_vm"
  node_name    = "pve-01"
  for_each     = local.k8s_nodes
  vm_name      = each.value.vm_name
  vm_id        = each.value.vm_id
  template_id  = local.ubuntu_template_id_26_04
  cpu_cores    = each.value.cpu_cores
  memory       = each.value.memory
  disk_size    = each.value.disk_size
  extra_disks  = each.value.extra_disks
  datastore_id = "local"
  nameservers  = ["192.168.0.1", "1.1.1.1", "8.8.8.8"]
  networks     = each.value.networks
  cloud_init_data = templatefile("${local.cloud_init_templates_dir}/general_vm_config.yaml", {
    hostname = each.value.vm_name
    username = "ubuntu"
    ssh_keys = local.ssh_keys
  })
}
