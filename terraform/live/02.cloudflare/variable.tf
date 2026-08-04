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

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_r2_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "Account ID"
  type        = string
}

variable "zone_id" {
  description = "DNS Zone ID"
  type        = string
}

variable "domain" {
  description = "DNS domain"
  type        = string
}

variable "mc_srv_name" {
  description = "Minecraft server srv record name"
  type        = string
}

variable "mc_target" {
  description = "Minecraft server srv target"
  type        = string
}

variable "gh_username" {
  description = "GitHub username"
  type        = string
}
