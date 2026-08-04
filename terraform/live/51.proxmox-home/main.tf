locals {
  ssh_keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDBWhBJ+7YbdJYnNzvHEpkkS4j9bgVHJRFCSWDZXL6adH6Z9XZylsfe3BU2YeieJekst/Vo/WPCYZTGinEN3yvxYhsKK0mvoA0Lwbhp9ExdnkCmaPpIDECC1l1l9AlBdPneE5H5ZwOsoaS8DooG8K22WBLvhJapKkSP05aIxZn9A2JRzfguptfGoQeJsCWZhsoPZCrwcdNqWDDRQlUsz1b2HvirkVbnlmkggLo+NnWcFb6CybmrXwIpgvi0ptPvdzdeA8rF6flVuvD0ALn6ywOR9lKwVCkBEYETo/7bLqS3sfdHwB4pctDP6bdqlm2ZDz/Q0VIZoqE2j1mZnCh8x6oTSxiIurrstJdQRQeASF+LscvuHn0ypqhccESqrdASZmjDKANm/3NZf74HJ20xkQ80e6Gwv9HsQ0DaglPWk3W/lDMxdySE1Hq1dUm7nq8RgHt3k2UISuoTBkMA1WZIc0485ibPFxqM4jBNATfO4Qjp+92awSBkDC5eNXUP744/feSkt0eY6fbpWFiDeajxRd43IePEtjRWiW7FWgW9uXa8Xj6g2vhBsYoljWJ23cHUPYzOBGK+QGZyPiggj8vkPT12sWoznDqAbo8dNBKtaLxkcRAKlhAX566kdrjY+PDOqF5e5pqo9LZpKpLGUzluJG3GZ94PCgbpnQvKQBeYJvJnjQ== kchawoon@naver.com",
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+XpFW8WRZcu3noIrPVidAyADg52sv/tjlV3OZ+zHHN chaewoon@spaceship"
  ]
}

module "couchdb" {
  source       = "../../modules/proxmox_lxc_container"
  node_name    = "pve-01"
  description  = "CouchDB LXC"
  datastore_id = "local"
  protection   = false

  vm_id             = 500
  network_interface = "vmbr0"
  disk_size         = 32
  hostname          = "couchdb"

  template_file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
  os_type          = "debian"
  ssh_keys         = local.ssh_keys

  tags = ["debian", "couchdb", "obsidian"]
}
