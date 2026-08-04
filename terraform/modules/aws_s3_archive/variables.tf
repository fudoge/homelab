variable "backup_bucket_name" {
  description = "Backup Bucket Name"
  type        = string
}

variable "transition_days_to_archive" {
  description = "Transition days to Glacier Deep Archive"
  type        = number
}

variable "expiration_days" {
  description = "Days to expire"
  type        = number
}

variable "backup_users" {
  description = "IAM principals allowed to read/write backup objects"
  type        = list(string)
}

variable "readonly_users" {
  description = "IAM principals allowed to list/get backup objects"
  type        = list(string)
}
