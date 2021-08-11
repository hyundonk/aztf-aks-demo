resource_group_name = "deleteme-aksdemo"
cluster_name = "hyukdemo"



bastion = {
  name              = "bastion"
  vm_num            = 1
  vm_size           = "Standard_D2s_v3"
  subnet_ip_offset  = 4
  prefix            = null
  postfix           = null
  vm_publisher      = "Canonical"
  vm_offer          = "UbuntuServer"
  vm_sku            = "18.04-LTS"
  vm_version        = "latest"
}

