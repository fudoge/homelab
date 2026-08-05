locals {
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBWhBJ+7YbdJYnNzvHEpkkS4j9bgVHJRFCSWDZXL6adH6Z9XZylsfe3BU2YeieJekst/Vo/WPCYZTGinEN3yvxYhsKK0mvoA0Lwbhp9ExdnkCmaPpIDECC1l1l9AlBdPneE5H5ZwOsoaS8DooG8K22WBLvhJapKkSP05aIxZn9A2JRzfguptfGoQeJsCWZhsoPZCrwcdNqWDDRQlUsz1b2HvirkVbnlmkggLo+NnWcFb6CybmrXwIpgvi0ptPvdzdeA8rF6flVuvD0ALn6ywOR9lKwVCkBEYETo/7bLqS3sfdHwB4pctDP6bdqlm2ZDz/Q0VIZoqE2j1mZnCh8x6oTSxiIurrstJdQRQeASF+LscvuHn0ypqhccESqrdASZmjDKANm/3NZf74HJ20xkQ80e6Gwv9HsQ0DaglPWk3W/lDMxdySE1Hq1dUm7nq8RgHt3k2UISuoTBkMA1WZIc0485ibPFxqM4jBNATfO4Qjp+92awSBkDC5eNXUP744/feSkt0eY6fbpWFiDeajxRd43IePEtjRWiW7FWgW9uXa8Xj6g2vhBsYoljWJ23cHUPYzOBGK+QGZyPiggj8vkPT12sWoznDqAbo8dNBKtaLxkcRAKlhAX566kdrjY+PDOqF5e5pqo9LZpKpLGUzluJG3GZ94PCgbpnQvKQBeYJvJnjQ== kchawoon@naver.com",
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+XpFW8WRZcu3noIrPVidAyADg52sv/tjlV3OZ+zHHN chaewoon@spaceship"
  ]

  vm_name  = "frr-router"
  username = "ubuntu"
}

data "terraform_remote_state" "templates" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "proxmox/global/templates/terraform.tfstate"
    region = var.region
  }
}

module "frrouter" {
  source       = "../../../modules/proxmox_vm"
  node_name    = "pve-01"
  vm_name      = local.vm_name
  vm_id        = 200
  template_id  = data.terraform_remote_state.templates.outputs.ubuntu_template_id["ubuntu_26_04"]
  cpu_cores    = 2
  memory       = 2048
  datastore_id = "local"
  disk_size    = 20
  extra_disks  = []
  nameservers  = ["192.168.0.1", "1.1.1.1", "8.8.8.8"]
  networks = [
    { bridge = "vmbr0", ip = "192.168.0.8/24", gw = "192.168.0.1" },
    { bridge = "vmbr1", ip = "192.168.10.1/24", gw = "" }
  ]
  cloud_init_data = templatefile("../99.cloud-init/frr-cloud-config.yaml", {
    hostname = local.vm_name
    username = local.username
    ssh_keys = local.ssh_keys
  })
}
