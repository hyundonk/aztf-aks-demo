# aks terraform module
https://registry.terraform.io/modules/Azure/aks/azurerm/latest

note)
To enable 'encryption at host', register the feature using CLI below.

az feature register --namespace "Microsoft.Compute" --name "EncryptionAtHost"
# wait until registered and invokoe below to get the change propagated
az provider register -n Microsoft.Compute

# to install kubectl
sudo az aks install-cli

# to get k8s credential
az aks get-credentials -n $clustername -g $rg



# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-enable-arc-enabled-clusters
az k8s-extension create --name azuremonitor-containers \
  --cluster-name <cluster-name> \
  --resource-group <resource-group> \
  --cluster-type connectedClusters \
  --extension-type Microsoft.AzureMonitor.Containers \
  --configuration-settings logAnalyticsWorkspaceResourceID=/subscriptions/87b7ed75-7074-41d6-9b53-3bf8894138bb/resourcegroups/deleteme-aksdemo/providers/microsoft.operationalinsights/workspaces/hyukdemo-workspace



