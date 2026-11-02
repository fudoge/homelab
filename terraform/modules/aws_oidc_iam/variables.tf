variable "role_name" {
  description = "Name of the IAM role assumed by the service account."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider."
  type        = string
}

variable "oidc_issuer_url" {
  description = "HTTPS issuer URL of the IAM OIDC provider."
  type        = string

  validation {
    condition     = startswith(var.oidc_issuer_url, "https://")
    error_message = "oidc_issuer_url must start with https://."
  }
}

variable "service_account_namespace" {
  description = "Kubernetes namespace of the service account."
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account name."
  type        = string
}

variable "audience" {
  description = "OIDC audience allowed to assume the role."
  type        = string
  default     = "sts.amazonaws.com"
}

variable "managed_policy_arns" {
  description = "ARNs of existing IAM managed policies to attach to the role."
  type        = set(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline IAM policy names to JSON policy documents."
  type        = map(string)
  default     = {}
}
