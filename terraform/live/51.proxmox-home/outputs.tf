output "couchdb_ipv4" {
  value = module.couchdb.ipv4
}

output "cp_1_ipv4" {
  value = module.k8s.ips
}
