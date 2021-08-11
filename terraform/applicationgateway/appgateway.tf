resource "azurerm_public_ip" "pip" {
	name                  	= format("%s-appgw-pip", var.prefix)
	location            	  = var.location
	resource_group_name  	  = var.resourcegroup_name
	allocation_method       = "Static"
  availability_zone       = "No-Zone"
	sku                     = "Standard" # Standard Load Balancer requires Standard public IP
	public_ip_prefix_id     = var.public_ip_prefix_id
}


resource "azurerm_application_gateway" "appgateway" {

	name = "${format("%s-appgw", var.prefix)}"
	resource_group_name  = "${var.resourcegroup_name}"
	location            = "${var.location}"

	sku {
		name     = "Standard_v2"
		tier     = "Standard_v2"
		capacity = 2
	}
/*
  autoscale_configuration {
    min_capacity = 2
    max_capacity = 20
  }
*/
	gateway_ip_configuration {
		name = "ipconfig" 
		subnet_id = var.subnet_id
	}  

	frontend_port {
		name = "frontend-https" 
		port = "443" 
	}

	frontend_port {
		name = "frontend-http" 
		port = "80" 
	}

  # a frontend with public IP is required.
	frontend_ip_configuration {
		name = format("%s-frontendip-public", var.prefix)
		public_ip_address_id = azurerm_public_ip.pip.id
	}

	frontend_ip_configuration {
		name = format("%s-frontendip-private", var.prefix)
		subnet_id = var.subnet_id
		private_ip_address = cidrhost(var.subnet_prefix, 4) 
		private_ip_address_allocation = "Static"
	}

	backend_address_pool {
			name = "http-listener-pool" 
	}

	backend_http_settings {
		name                  = "default" 
		port                  = 80
		protocol              = "Http"
		cookie_based_affinity = "Disabled"
		#cookie_based_affinity = "Enabled"
		request_timeout = "30" 
		probe_name            = format("probe-%s", var.site1_hostname)
	}

	http_listener {
		name                            = format("%s-https", var.site1_hostname)
		frontend_ip_configuration_name  = format("%s-frontendip-private", var.prefix)
		frontend_port_name              = "frontend-https" 
		protocol                        = "Https" 
		ssl_certificate_name            = var.site1_hostname
	#	require_sni                     = "true" 
	#	host_name                       = var.site1_hostname
	}

	http_listener {
		name                            = format("%s-http", var.site1_hostname)
		frontend_ip_configuration_name  = format("%s-frontendip-private", var.prefix)
		frontend_port_name              = "frontend-http" 
		protocol                        = "Http" 
	#	host_name                       = var.site1_hostname
	}

	request_routing_rule {
		name                            = "ruleHttps" 
		rule_type                       = "Basic"
		http_listener_name              = format("%s-https", var.site1_hostname)
		backend_address_pool_name       = "http-listener-pool" 
		backend_http_settings_name      = "default" 
	}

	request_routing_rule {
		name                            = "ruleHttp" 
		rule_type                       = "Basic"
		http_listener_name              = format("%s-http", var.site1_hostname)
		backend_address_pool_name       = "http-listener-pool" 
		backend_http_settings_name      = "default" 
	}

	ssl_certificate {
		name                            = var.site1_hostname
		data                            = filebase64(var.site1_cert)
		#data                           = filebase64(format("./%s.pfx", var.site1_hostname))
		#data                           = base64encode(file(format("./%s.pfx", var.site1_hostname)))
		password                        = var.site1_cert_password
	}
/*
	waf_configuration {
		enabled          = "true"
		firewall_mode    = "Detection"
		rule_set_type    = "OWASP"
		rule_set_version = "3.0"
	}
*/
	probe {
		name                            = format("probe-%s", var.site1_hostname)
		protocol                        = "http"
		path                            = "/?a=probe"
		host                            = format("%s", var.site1_hostname)
		
		interval                        = "10"
		timeout                         = "10"
		unhealthy_threshold             = "2"
	}
}

output "application_gateway_id" {
    value = azurerm_application_gateway.appgateway.id
}

/*
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "association" {
	count = "${var.instance_num}"
	
	network_interface_id    = "${element(azurerm_network_interface.nic.*.id, count.index)}"
	ip_configuration_name = "${join("", list("config", "0"))}"
	backend_address_pool_id = "${azurerm_application_gateway.appgateway.backend_address_pool.0.id}"

}

resource "azurerm_availability_set" "avset" {
	name                  = "${format("%s-avset", var.servicename)}"
	location              = "${var.location}"
	resource_group_name  = "${var.resourcegroup_name}"
	platform_update_domain_count = 5 // Korea regions support up to 2 fault domains
	platform_fault_domain_count = 2 // Korea regions support up to 2 fault domains

	managed = true
}

resource "azurerm_network_interface" "nic" {
	count = "${var.instance_num}"
	name = "${format("%s-%02d-nic", var.servicename, count.index + 1)}"
	location            = "${var.location}"
	resource_group_name  = "${var.resourcegroup_name}"
	
	ip_configuration {
			name = "${join("", list("config", "0"))}"
			subnet_id = "${data.terraform_remote_state.network.outputs.subnet_auction_ext_01}"
			private_ip_address_allocation = "${length("${var.static_ip_range}") > 0 ? "static" : "dynamic"}"	
			private_ip_address = "${length("${var.static_ip_range}") > 0 ? cidrhost("${var.static_ip_range}", 250 + count.index) : ""}" 
	
	}
}

resource "azurerm_virtual_machine" "vm" {
	name = "${format("%s%02d", var.servicename, count.index + 1)}"
	location            = "${var.location}"
	resource_group_name  = "${var.resourcegroup_name}"
	vm_size               = "${var.instance_size}"

	count = "${var.instance_num}"
	
	availability_set_id = "${azurerm_availability_set.avset.id}"	

	storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

	storage_os_disk {
    	name = "${format("%s-%02d-OsDisk", var.servicename, count.index + 1)}"
		caching           = "ReadWrite"
		create_option     = "FromImage"
		managed_disk_type = "Standard_LRS"
	}

	os_profile {
    	computer_name = "${format("%s%02d", var.servicename, count.index + 1)}"
		admin_username = "${var.adminUsername}"
		admin_password = "${var.adminPassword}"
	}

	os_profile_linux_config {
        disable_password_authentication = false
    }

	network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]

}

output "backend_network_interface_ids" {
	value = "${azurerm_network_interface.nic.*.id}"
}
*/

