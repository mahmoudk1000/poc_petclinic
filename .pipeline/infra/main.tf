locals {
  name = "petclinic"
  tags = {
    Application = "petclinic"
    Author      = "Mahmoud Ayman (mahmoudk1000)"
  }
}

resource "azurerm_resource_group" "main" {
  name     = local.name
  location = "West Europe"

  tags = local.tags
}

module "network" {
  source              = "Azure/subnets/azurerm"
  version             = "1.0.0"
  resource_group_name = azurerm_resource_group.main.name

  subnets = {
    aks = {
      address_prefixes  = ["10.52.0.0/16"]
      service_endpoints = ["Microsoft.Storage"]
    }
  }

  virtual_network_address_space = ["10.52.0.0/16"]
  virtual_network_location      = azurerm_resource_group.main.location
  virtual_network_name          = "${local.name}-vnet"
  virtual_network_tags          = local.tags
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "9.1.0"

  prefix              = "${local.name}-cluster"
  resource_group_name = azurerm_resource_group.main.name

  kubernetes_version = var.kube_version

  enable_auto_scaling = true
  agents_count        = var.agent_count
  agents_min_count    = var.agents_min_count
  agents_max_count    = var.agents_max_count
  agents_size         = var.agent_vm_size
  os_disk_size_gb     = var.os_disk_size_gb
  sku_tier            = "Free"
  agents_pool_name    = "system"
  public_ssh_key      = file(var.ssh_key_path)
  agents_type         = "VirtualMachineScaleSets"

  workload_identity_enabled         = true
  enable_host_encryption            = false
  role_based_access_control_enabled = true
  rbac_aad                          = false
  private_cluster_enabled           = false
  log_analytics_workspace_enabled   = false
  oidc_issuer_enabled               = true

  agents_labels = {
    "nodepool" : "defaultnodepool"
  }

  agents_tags = {
    "Agent" : "defaultnodepoolagent"
  }

  network_plugin                               = "azure"
  network_policy                               = "azure"
  net_profile_dns_service_ip                   = "10.0.0.10"
  net_profile_service_cidr                     = "10.0.0.0/16"
  vnet_subnet_id                               = module.network.vnet_subnets_name_id["aks"]
  network_contributor_role_assigned_subnet_ids = { "aks" = module.network.vnet_subnets_name_id["aks"] }

  depends_on = [module.network]

  tags = local.tags
}
