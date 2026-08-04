output "ips" {
  value = [for network in var.networks : split("/", network.ip)[0]]
}
