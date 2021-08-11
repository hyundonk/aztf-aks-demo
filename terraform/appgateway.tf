resource "azurerm_virtual_network" "ingress-vnet" {
	name                = "ingress-vnet"
	location 			        = azurerm_resource_group.example.location
	resource_group_name		= azurerm_resource_group.example.name
	address_space         = ["10.40.0.0/16"]
}

resource "azurerm_subnet" "mysubnet" {
	name                    	= "mySubnet"
	resource_group_name		    = azurerm_resource_group.example.name
	virtual_network_name    	= azurerm_virtual_network.ingress-vnet.name
	address_prefixes         	= ["10.40.0.0/24"]
}

resource "azurerm_virtual_network_peering" "appgwtoaks" {
  name                      = "AppGWtoAKSVnetPeering"

	resource_group_name		        = azurerm_resource_group.example.name
  virtual_network_name          = azurerm_virtual_network.ingress-vnet.name

  remote_virtual_network_id     = module.network.vnet_id

  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
  allow_gateway_transit         = false
}
/*
resource "azurerm_virtual_network_peering" "akstoappgw" {
  name                      = "AKStoAppGWVnetPeering"

  resource_group_name           = azurerm_resource_group.example.name
  virtual_network_name          = module.network.vnet_id

  remote_virtual_network_id     = azurerm_virtual_network.ingress-vnet.id

  allow_virtual_network_access  = true
  allow_forwarded_traffic       = true
  allow_gateway_transit         = false
}
*/
module "appgateway" {
	source                  = "./applicationgateway"

  prefix                  = "ingress"

	location 			          = azurerm_resource_group.example.location
	resourcegroup_name		  = azurerm_resource_group.example.name
  
  subnet_id               = azurerm_subnet.mysubnet.id
  subnet_prefix           = azurerm_subnet.mysubnet.address_prefix

  site1_hostname          = "w1.grilledsalmon.me"
  site1_cert              = "./grilledsalmon.me.pfx"
  site1_cert_password     = "Djfudnsdkagh1!"

  public_ip_prefix_id     = null
}

output "application_gateway_id" {
    value = module.appgateway.application_gateway_id
}


