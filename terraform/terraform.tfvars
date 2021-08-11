resource_group_name = "dev-infracm"
cluster_name = "hyukdemo"
subnet_id=""
log_analytics_workspace_id=""

cliend_id={client_id here}
client_secret={client_secret here}


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

