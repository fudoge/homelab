# proxmox_vm

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.12.5 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | 0.111.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | 0.111.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [proxmox_virtual_environment_file.cloud_config](https://registry.terraform.io/providers/bpg/proxmox/0.111.1/docs/resources/virtual_environment_file) | resource |
| [proxmox_virtual_environment_vm.vm](https://registry.terraform.io/providers/bpg/proxmox/0.111.1/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cloud_init_data"></a> [cloud\_init\_data](#input\_cloud\_init\_data) | n/a | `string` | n/a | yes |
| <a name="input_cpu_cores"></a> [cpu\_cores](#input\_cpu\_cores) | n/a | `number` | n/a | yes |
| <a name="input_datastore_id"></a> [datastore\_id](#input\_datastore\_id) | n/a | `string` | n/a | yes |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | n/a | `number` | n/a | yes |
| <a name="input_memory"></a> [memory](#input\_memory) | n/a | `number` | n/a | yes |
| <a name="input_networks"></a> [networks](#input\_networks) | n/a | <pre>list(object({<br/>    bridge = string<br/>    ip     = string<br/>    gw     = string<br/>  }))</pre> | n/a | yes |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | n/a | `string` | n/a | yes |
| <a name="input_template_id"></a> [template\_id](#input\_template\_id) | n/a | `string` | n/a | yes |
| <a name="input_vm_id"></a> [vm\_id](#input\_vm\_id) | n/a | `number` | n/a | yes |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ips"></a> [ips](#output\_ips) | n/a |
<!-- END_TF_DOCS -->
