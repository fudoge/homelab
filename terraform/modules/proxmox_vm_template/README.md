# proxmox_vm_template

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
| [proxmox_download_file.cloud_image](https://registry.terraform.io/providers/bpg/proxmox/0.111.1/docs/resources/download_file) | resource |
| [proxmox_virtual_environment_vm.template](https://registry.terraform.io/providers/bpg/proxmox/0.111.1/docs/resources/virtual_environment_vm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_datastore_id"></a> [datastore\_id](#input\_datastore\_id) | n/a | `string` | `"local"` | no |
| <a name="input_image_url"></a> [image\_url](#input\_image\_url) | n/a | `string` | n/a | yes |
| <a name="input_template_id"></a> [template\_id](#input\_template\_id) | n/a | `number` | n/a | yes |
| <a name="input_template_name"></a> [template\_name](#input\_template\_name) | n/a | `string` | n/a | yes |
| <a name="input_ve_node_name"></a> [ve\_node\_name](#input\_ve\_node\_name) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | n/a |
<!-- END_TF_DOCS -->
