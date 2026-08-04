variable "description" {
  type        = string
  description = "LXC description"
}

variable "node_name" {
  type        = string
  description = "Proxmox node name"
}

variable "vm_id" {
  type        = number
  description = "LXC VM ID"
}

variable "protection" {
  type        = bool
  description = "Whether to prevent data"
}

variable "hostname" {
  type        = string
  description = "Container hostname"
}

variable "ssh_keys" {
  type        = list(string)
  description = "SSH public keys for root account"
  default     = []
}

variable "network_interface" {
  type        = string
  description = "Container network interface name"
}

variable "datastore_id" {
  type        = string
  description = "Datastore ID for root disk"
}

variable "disk_size" {
  type        = number
  description = "Root disk size in GB"
}

variable "template_file_id" {
  type        = string
  description = "OS template file ID"
}

variable "os_type" {
  type        = string
  description = "Container OS type"

  validation {
    condition = contains([
      "alpine",
      "archlinux",
      "centos",
      "debian",
      "devuan",
      "fedora",
      "gentoo",
      "nixos",
      "opensuse",
      "ubuntu",
      "unmanaged"
    ], var.os_type)
    error_message = "os_type must be one of the supported Proxmox LXC OS types."
  }
}

variable "mount_points" {
  description = "Additional mount points for the container"
  type = list(object({
    path          = string
    volume        = string
    size          = optional(string)
    read_only     = optional(bool)
    backup        = optional(bool)
    replicate     = optional(bool)
    shared        = optional(bool)
    quota         = optional(bool)
    acl           = optional(bool)
    mount_options = optional(list(string))
  }))
  default = []
}

variable "tags" {
  description = "Tags"
  type        = list(string)
}
