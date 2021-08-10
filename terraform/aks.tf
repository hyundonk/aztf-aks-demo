resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.example.name
  address_space       = "10.1.0.0/16"
  subnet_prefixes     = ["10.1.0.0/22", "10.1.128.0/24"]
  subnet_names        = ["subnet1", "subnet-bastion"]

  subnet_enforce_private_link_endpoint_network_policies = {
                                                            "subnet1" : true
                                                          }
  depends_on          = [azurerm_resource_group.example]
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.cluster_name}-workspace"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018" 
  retention_in_days   = 31 # no charge for up to first 31 days. range: 30-730 (days)
}

resource "azurerm_log_analytics_solution" "main" {
  solution_name         = "ContainerInsights"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
 
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_kubernetes_cluster" "main" {
  name                    = var.cluster_name
  kubernetes_version      = var.cluster_version # kubernetes version
  location                = azurerm_resource_group.example.location
  resource_group_name     = azurerm_resource_group.example.name
  dns_prefix              = var.cluster_name
  sku_tier                = "Free" # "Free" or "Paid"
  private_cluster_enabled = true # make a private aks cluster

  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = file(var.ssh_public_key_path)
    }
  }

  default_node_pool {
    orchestrator_version    = var.cluster_version
    name                    = "nodepool01"
    node_count              = 3
    vm_size                 = var.vm_size
    os_disk_size_gb         = 50
    vnet_subnet_id          = module.network.vnet_subnets[0]
    enable_auto_scaling     = false 
    max_count               = null
    min_count               = null
    enable_node_public_ip   = false
    availability_zones      = null
    node_labels             = {
                              "nodepool" : "defaultnodepool"
                            }
    type                    = "VirtualMachineScaleSets" # either VirtualMachineScaleSets or AvailabilitySet 
    tags                    = {}
    max_pods                = 100 # default 30, maximum 250
    enable_host_encryption  = true # https://docs.microsoft.com/en-us/azure/aks/enable-host-encryption
  }

  
  # service_principal {
    #  use managed identity below instead
  #}

  identity {
    type = "SystemAssigned" # "SystemAssigned" or "UserAssigned"
  }

  addon_profile {
    kube_dashboard {
      enabled = false
    }

    azure_policy {
      enabled = true
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    }
  }

  #role_based_access_control {
  #  enabled = true
  #  azure_active_directory {
  #    managed = true
  #    admin_group_object_ids = [azuread_group.aks_cluster_admins.object_id]
  #  }
  #}

  network_profile {
    network_plugin     = "azure" # "azure" CNI or "kubenet" 
    network_policy     = "calico" # "azure" NetworkPolicy or "calico"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    outbound_type      = "loadBalancer" # "loadBalancer" or "userDefinedRouting" 
    service_cidr       = "10.0.0.0/16"
  }

  tags = {}
}


