variable "vm_name" {
  type = string
}

variable "node_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "template_id" {
  type = string
}

variable "cpu_cores" {
  type = number
}

variable "memory" {
  type = number
}

variable "datastore_id" {
  type = string
}

variable "disk_size" {
  type = number
}

variable "networks" {
  type = list(object({
    bridge = string
    ip     = string
    gw     = string
  }))
}

variable "ssh_keys" {
  type = list(string)
}

variable "username" {
  type = string
}
variable "cloud_init_data" {
  type = string
}
