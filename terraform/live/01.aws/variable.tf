variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "state_bucket_name" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = "riveroverflow-homelab-iac-remote-state"
}

variable "notification_email" {
  description = "Email address for SNS notification"
  type        = string
}

variable "heartbeat_func_name" {
  description = "heartbeat function name"
  type        = string
  default     = "homelab-heartbeat"
}

variable "heartbeat_token" {
  description = "heartbeat auth token(hashed)"
  type        = string
  sensitive   = true
}

variable "cloudwatch_heartbeat_ns" {
  description = "cloudwatch heartbeat namespace"
  type        = string
  default     = "homelab/heartbeat"
}
