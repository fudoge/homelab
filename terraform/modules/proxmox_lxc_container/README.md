# proxmox_lxc_container

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.12.5 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | 0.111.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.9.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | 0.111.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [proxmox_virtual_environment_container.container](https://registry.terraform.io/providers/bpg/proxmox/0.111.1/docs/resources/virtual_environment_container) | resource |
| [random_password.container](https://registry.terraform.io/providers/hashicorp/random/3.9.0/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_datastore_id"></a> [datastore\_id](#input\_datastore\_id) | Datastore ID for root disk | `string` | n/a | yes |
| <a name="input_description"></a> [description](#input\_description) | LXC description | `string` | n/a | yes |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Root disk size in GB | `number` | n/a | yes |
| <a name="input_hostname"></a> [hostname](#input\_hostname) | Container hostname | `string` | n/a | yes |
| <a name="input_mount_points"></a> [mount\_points](#input\_mount\_points) | Additional mount points for the container | <pre>list(object({<br/>    path          = string<br/>    volume        = string<br/>    size          = optional(string)<br/>    read_only     = optional(bool)<br/>    backup        = optional(bool)<br/>    replicate     = optional(bool)<br/>    shared        = optional(bool)<br/>    quota         = optional(bool)<br/>    acl           = optional(bool)<br/>    mount_options = optional(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_network_interface"></a> [network\_interface](#input\_network\_interface) | Container network interface name | `string` | n/a | yes |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | Proxmox node name | `string` | n/a | yes |
| <a name="input_os_type"></a> [os\_type](#input\_os\_type) | Container OS type | `string` | n/a | yes |
| <a name="input_protection"></a> [protection](#input\_protection) | Whether to prevent data | `bool` | n/a | yes |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | SSH public keys for root account | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags | `list(string)` | n/a | yes |
| <a name="input_template_file_id"></a> [template\_file\_id](#input\_template\_file\_id) | OS template file ID | `string` | n/a | yes |
| <a name="input_vm_id"></a> [vm\_id](#input\_vm\_id) | LXC VM ID | `number` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_container_password"></a> [container\_password](#output\_container\_password) | n/a |
| <a name="output_ipv4"></a> [ipv4](#output\_ipv4) | n/a |
<!-- END_TF_DOCS -->
