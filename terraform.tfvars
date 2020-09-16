# input variables 

# declare below environmental variables in the bash shell to pass required terraform variables
#export TF_VAR_client_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxx"
#export TF_VAR_client_secret="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxx"

#export TF_VAR_tenant_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxx"
#export TF_VAR_aad_group_id="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxx"

#export TF_VAR_adminusername="adminusername"
#export TF_VAR_adminpassword="adminpassword"

#export TF_VAR_sql_user="sqlusername"
#export TF_VAR_sql_password="sqlpassword"
#export TF_VAR_sql_dbname="sqldbname"

#export TF_VAR_nodepool_principalid="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxxx"
#export TF_VAR_keyvault_allowed_ip="ip-address-of-terraform-machine"


cluster_name        = "aks112"
dns_prefix          = "aks112"
resource_group_name = "aks-demo"
location            = "koreacentral"

log_analytics_workspace_name = "aks112"
log_analytics_workspace_location = "koreacentral"


