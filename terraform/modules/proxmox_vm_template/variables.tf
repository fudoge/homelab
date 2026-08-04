variable "template_id" {
  type = number
}

variable "template_name" {
  type = string
}

variable "ve_node_name" {
  type = string
}

variable "datastore_id" {
  type    = string
  default = "local"
}

variable "image_url" {
  type = string
}
