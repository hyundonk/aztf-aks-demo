
module "bastion_pip" {
  source  = "github.com/hyundonk/aztf-module-pip"
  
  prefix  = "demo"
  
  services = {
    0       =  {
      name  = "bastion"
    }
  }

  location = azurerm_resource_group.example.location
  rg       = azurerm_resource_group.example.name

  tags     = null
}

module "example" {
  source  = "github.com/hyundonk/aztf-module-vm"

  instances = var.bastion

  location                          = azurerm_resource_group.example.location
  resource_group_name               = azurerm_resource_group.example.name

  subnet_id                         = module.network.vnet_subnets[1]
  subnet_prefix                     = "10.1.128.0/24"

  admin_username                    = var.admin_username

  ssh_key_data                      = file(var.ssh_public_key_path)
  ssh_key_path                      = "/home/${var.admin_username}/.ssh/authorized_keys"

  public_ip_id                      = module.bastion_pip.public_ip[0].id
}

output "bastion_ip" {
  value = module.bastion_pip.public_ip[0].ip_address
}

