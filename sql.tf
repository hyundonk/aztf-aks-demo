resource "azurerm_resource_group" "sql" {
    name     = "${var.resource_group_name}-sql"
    location = var.location
}

resource "azurerm_storage_account" "sql" {
  name                      = "sa${var.cluster_name}"
  resource_group_name       = azurerm_resource_group.sql.name
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
}

resource "azurerm_sql_server" "example" {
  lifecycle {
    ignore_changes = [
      extended_auditing_policy
    ]
  }

  name                         = "sqlserver${var.cluster_name}"
  resource_group_name          = azurerm_resource_group.sql.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.adminusername
  administrator_login_password = var.adminpassword
  
  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.sql.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.sql.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }

  tags = {
    environment = "production"
  }
}

# allow connection from kubernetes node pool subnet
resource "azurerm_sql_virtual_network_rule" "sqlvnetrule" {
  name                = "vnet-service-endpoint-subnet-external"
  resource_group_name = azurerm_resource_group.sql.name
  server_name         = azurerm_sql_server.example.name
  subnet_id           = azurerm_subnet.ext.id
}

resource "azurerm_sql_database" "example" {
  name                = "mydrivingDB"
  resource_group_name = azurerm_resource_group.sql.name
  location            = var.location
  server_name         = azurerm_sql_server.example.name

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.sql.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.sql.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }

  tags = {
    environment = "production"
  }
}

