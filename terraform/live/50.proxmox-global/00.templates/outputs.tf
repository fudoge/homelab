output "ubuntu_template_id" {
  value = { for name, template in module.ubuntu_template :
    name => template.id
  }
}
