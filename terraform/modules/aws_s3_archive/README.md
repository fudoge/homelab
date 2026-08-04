# aws_s3_archive

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.12.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.57.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.57.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket.backup_bucket](https://registry.terraform.io/providers/hashicorp/aws/6.57.1/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.backup_bucket_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/6.57.1/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.backup_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/6.57.1/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.backup_bucket_public_acls](https://registry.terraform.io/providers/hashicorp/aws/6.57.1/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.backup_bucket_sse_conf](https://registry.terraform.io/providers/hashicorp/aws/6.57.1/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_iam_policy_document.backup_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/6.57.1/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_backup_bucket_name"></a> [backup\_bucket\_name](#input\_backup\_bucket\_name) | Backup Bucket Name | `string` | n/a | yes |
| <a name="input_backup_users"></a> [backup\_users](#input\_backup\_users) | IAM principals allowed to read/write backup objects | `list(string)` | n/a | yes |
| <a name="input_expiration_days"></a> [expiration\_days](#input\_expiration\_days) | Days to expire | `number` | n/a | yes |
| <a name="input_readonly_users"></a> [readonly\_users](#input\_readonly\_users) | IAM principals allowed to list/get backup objects | `list(string)` | n/a | yes |
| <a name="input_transition_days_to_archive"></a> [transition\_days\_to\_archive](#input\_transition\_days\_to\_archive) | Transition days to Glacier Deep Archive | `number` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | n/a |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | n/a |
<!-- END_TF_DOCS -->
