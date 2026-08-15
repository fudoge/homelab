variable "region" {
  description = "AWS state backend region"
  type        = string
  default     = "ap-northeast-2"
}

variable "state_bucket_name" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "riveroverflow-homelab-iac-remote-state"
}
variable "ts_oauth_client_id" {
  type      = string
  sensitive = true
}

variable "ts_oauth_client_secret" {
  type      = string
  sensitive = true
}
