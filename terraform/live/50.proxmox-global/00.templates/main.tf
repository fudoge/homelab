locals {
  ubuntu_templates = {
    ubuntu_24_04 = {
      template_id   = 100
      template_name = "ubuntu-24-04"
      image_url     = "https://cloud-images.ubuntu.com/noble/20260801/noble-server-cloudimg-amd64.img"
    },
    ubuntu_26_04 = {
      template_id   = 101
      template_name = "ubuntu-26-04"
      image_url     = "https://cloud-images.ubuntu.com/resolute/20260720/resolute-server-cloudimg-amd64.img"
    }
  }
}

module "ubuntu_template" {
  for_each = local.ubuntu_templates

  source        = "../../../modules/proxmox_vm_template"
  template_id   = each.value.template_id
  template_name = each.value.template_name
  ve_node_name  = "pve-01"
  datastore_id  = "local"
  image_url     = each.value.image_url
}
