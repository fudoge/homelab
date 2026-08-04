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

variable "proxmox_api_token" {
  type      = string
  sensitive = true
}
