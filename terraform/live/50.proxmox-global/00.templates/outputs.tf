output "ubuntu_template_id" {
  value = { for name, template in module.ubuntu_template :
    name => template.id
  }
}

output "nixos_template_id" {
  value = module.nixos_template.id
}
