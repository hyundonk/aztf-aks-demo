variable "client_id" {}
variable "client_secret" {}

variable "agent_count" {
    default = 2
}

variable "ssh_public_key" {
    default = "~/.ssh/id_rsa.pub"
}

variable "dns_prefix" {
}

variable cluster_name {
}

variable resource_group_name {
}

variable location {
}

variable log_analytics_workspace_name {
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing 
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}

variable tenant_id {
    description = "tenant ID used for Azure AD application"
    default = null
}

variable aad_group_id {
    description = "Azure AD group ID for cluster admin role"
    default = null
}

variable nodepool_principalid {
  description = "printcipalId of system-assigned managed identity on the nodepool"
}

variable keyvault_allowed_ip {
  description = "source IP whitelist to be added to key vault network firewall."
}

# variables for SQL
variable adminusername {

}

variable adminpassword {

}

# variable for key vault secrets
variable sql_server{}
variable sql_password{}
variable sql_user{}
variable sql_dbname{}



