resource "azurerm_resource_group" "k8s" {
    name     = var.resource_group_name
    location = var.location
}

resource "random_id" "log_analytics_workspace_name_suffix" {
    byte_length = 8
}

resource "azurerm_log_analytics_workspace" "test" {
    # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
    name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
    location            = var.log_analytics_workspace_location
    resource_group_name = azurerm_resource_group.k8s.name
    sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "test" {
    solution_name         = "ContainerInsights"
    location              = azurerm_log_analytics_workspace.test.location
    resource_group_name   = azurerm_resource_group.k8s.name
    workspace_resource_id = azurerm_log_analytics_workspace.test.id
    workspace_name        = azurerm_log_analytics_workspace.test.name

    plan {
        publisher = "Microsoft"
        product   = "OMSGallery/ContainerInsights"
    }
}

resource "azurerm_virtual_network" "vnet" {

	name                = "myvnet"
	location 			        = azurerm_resource_group.k8s.location
	resource_group_name		= azurerm_resource_group.k8s.name
	address_space         = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "ext" {
	name                    	= "external"
	resource_group_name		    = azurerm_resource_group.k8s.name
	virtual_network_name    	= azurerm_virtual_network.vnet.name
	address_prefixes         	= ["10.20.0.0/24"]

  # allow service endpoints to SQL 
  service_endpoints         = ["Microsoft.Sql", "Microsoft.KeyVault"]
}

resource "azurerm_kubernetes_cluster" "k8s" {
  lifecycle {
    ignore_changes = [
      addon_profile
    ]
  }
    name                = var.cluster_name
    location            = azurerm_resource_group.k8s.location
    resource_group_name = azurerm_resource_group.k8s.name
    dns_prefix          = var.dns_prefix

    kubernetes_version = "1.17.9"
    linux_profile {
        admin_username = "ubuntu"

        ssh_key {
            key_data = file(var.ssh_public_key)
        }
    }

    default_node_pool {
        name            = "agentpool"
        node_count      = var.agent_count
        vm_size         = "Standard_D2s_v3"
        type            = "VirtualMachineScaleSets"
        vnet_subnet_id  = azurerm_subnet.ext.id
    }

    network_profile {
      network_plugin = "azure"
      load_balancer_sku = "standard" 
    }

    windows_profile {
      admin_username = var.adminusername
      admin_password = var.adminpassword
    }

    role_based_access_control {
      azure_active_directory {
        managed = true
        tenant_id = var.tenant_id
        admin_group_object_ids = [var.aad_group_id]
      }
      enabled = true
    }

    # Either identity or service_principal blocks must be specified 
    identity {
      type = "SystemAssigned"
    }
 
    addon_profile {
        oms_agent {
          enabled                    = true
          log_analytics_workspace_id = azurerm_log_analytics_workspace.test.id
        }

        kube_dashboard {
          enabled = false
        }
    }

    tags = {
        Environment = "Development"
    }
}

