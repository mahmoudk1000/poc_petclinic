output "client_certificate" {
  value     = module.aks.client_certificate
  sensitive = true
}

output "kube_config_raw" {
  value     = module.aks.kube_config_raw
  sensitive = true
}
