
resource "azurerm_network_security_group" "bastion" {
	name                  		= "nsg-bastion"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = module.network.vnet_subnets[1]
  network_security_group_id = azurerm_network_security_group.bastion.id
}

resource "azurerm_network_security_rule" "rule" {
	name                            = "allow-ssh-in"
  resource_group_name             = azurerm_resource_group.example.name
	
	priority                        = "1000"
	direction                       = "Inbound"
	access                          = "Allow"
	protocol                        = "Tcp"

	source_port_range              	= "*"
	source_port_ranges             	= null
	destination_port_range          = "22"
	destination_port_ranges         = null
	source_address_prefix           = "*"
	source_address_prefixes         = null
	destination_address_prefix      = "*"
	destination_address_prefixes    = null

	network_security_group_name     = azurerm_network_security_group.bastion.name
}



