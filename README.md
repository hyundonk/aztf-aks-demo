# Azure Kubernetes Service (AKS) Hands-on Demo

This demo shows how to create AKS cluster with enterprise-level security following below construction sets.

https://github.com/Azure/caf-terraform-landingzones-starter/blob/starter/enterprise_scale/construction_sets/aks/online/aks_secure_baseline/standalone/docs/terraform.md



Target AKS Cluster 구성 configuration 

| cluster  type                                       | private                 |
| --------------------------------------------------- | ----------------------- |
| kubernetes  version                                 | 1.21.2                  |
| max # of pods                                       | 100                     |
| host  encryption                                    | yes                     |
| # of nodepool                                       | 1                       |
| nodepool type                                       | VirtualMachineScaleSets |
| # of node                                           | 3                       |
| autoscaling                                         | FALSE                   |
| authorization  method to acess other azure services | Managed Identity        |
| Azure Monitor  for container                        | enabled                 |
| Network Policy                                      | aszure CNI              |

## Pre-requisites

### 

```bash
# Azure Monitor 연동을 위해 아래 provider 등록이 필요
az provider show -n Microsoft.OperationsManagement -o table
az provider show -n Microsoft.OperationalInsights -o table

az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights

# az login
az login 
```



## AKS 생성하기 (Terraform) - Terraform

AKS  resource에 대한 terraform code: ./terraform/

```bash
git clone https://github.com/hyundonk/aztf-aks-demo
cd aztf-aks-demo/terraform/

terraform init -backend-config="storage_account_name={storage-account-name}" -backend-config="container_name={container-name}" -backend-config="access_key={storage-account-key}" -backend-config="key={blob-name}"

terraform plan
terraform apply
```



## AKS 생성하기 (Terraform) - Azure CLI

ref) https://docs.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az_aks_create

```bash
# define environmental variables
resource_group_name=deleteme-aksdemo2
location=koreacentral
vnet_name=myaksdemovnet
cluster_name=hyukdemo2
admin_username=azureuser
version=1.21.2
vm_size=Standard_D4s_v3

loganalytics_workspace_id=$(az monitor log-analytics workspace show --resource-group deleteme-aksdemo --workspace-name hyukdemo-workspace --query id -o tsv)

# create a resource group
az group create --name $resource_group_name --location $location

# create a virtual network
az network vnet create \
  --name $vnet_name \
  --address-prefixes 10.2.0.0/16 \
  --resource-group $resource_group_name \
  --subnet-name default \
  --subnet-prefix 10.2.0.0/22

# get subnet_id
subnet_id=$(az network vnet subnet list -g $resource_group_name --vnet-name $vnet_name --query "[?name=='default'].id" --output tsv)

# create aks cluster
az aks create -g $resource_group_name -n $cluster_name --kubernetes-version $version \
			 --location $location \
			 --dns-name-prefix $cluster_name \
			 --enable-private-cluster \
			 --generate-ssh-keys \
			 --admin-username $admin_username \
			 --generate-ssh-keys \
			 --nodepool-name nodepool01 \
			 --node-count 3 \
			 --node-vm-size $vm_size \
			 --node-osdisk-size 50 \
			 --vnet-subnet-id $subnet_id \
			 --nodepool-labels nodepool=defaultnodepool \
			 --vm-set-type VirtualMachineScaleSets \
			 --max-pods 100 \
			 --enable-encryption-at-host \
			 --enable-managed-identity \
			 --enable-addons monitoring,azure-policy \
			 --workspace-resource-id $loganalytics_workspace_id \
			 --network-plugin azure \
			 --network-policy calico \
			 --dns-service-ip 10.0.0.10 \
			 --docker-bridge-address 172.17.0.1/16 \
			 --outbound-type loadBalancer \
			 --service-cidr 10.0.0.0/16 \
			 -enable-azure-rbac
```

### How to enable Azure AD integration 

cluster의 API server 접근시  Azure AD를 통해 사용자를 인증하여 보안 강화를 강화할 수 있음.

![Azure Active Directory integration with AKS clusters](https://docs.microsoft.com/en-us/azure/aks/media/concepts-identity/aad-integration.png)

Ref) https://docs.microsoft.com/en-us/azure/aks/concepts-identity#azure-ad-integration

```
# Create Azure AD group to use for cluster administration
az ad group create --display-name myAKSAdminGroup --mail-nickname myAKSAdminGroup

# update cluster to enable azure ad integration
az aks update -g $resource_group_name -n $cluster_name --enable-aad --aad-admin-group-object-ids <id-1> 
```



### How to enable Azure RBAC for Kubernetes Authorization

Kubernetes RBAC (RoleBinding/ClusterRoleBindings) 대신 Azure RBAC을 사용하여 인증

![Azure RBAC for Kubernetes authorization flow](https://docs.microsoft.com/en-us/azure/aks/media/concepts-identity/azure-rbac-k8s-authz-flow.png)

Azure RBAC built-in roles

- Azure Kubernetes Service RBAC Viewer
- Azure Kubernetes Service RBAC Writer
- Azure Kubernetes Service RBAC Admin
- Azure Kubernetes Service RBAC Cluster Admin



```
# update cluster to enable azure RBAC
az aks update -g myResourceGroup -n myAKSCluster --enable-azure-rbac
```





## Deploying Application Gateway Ingress Controller

![Azure Application Gateway + AKS](https://docs.microsoft.com/en-us/azure/application-gateway/media/application-gateway-ingress-controller-overview/architecture.png)

```
# Enable the AGIC add-on in existing AKS cluster through Azure CLI
applicationgateway_name=ingress-appgw

appgwId=$(az network application-gateway show -n $applicationgateway_name -g $resource_group_name -o tsv --query "id") 
az aks enable-addons -n $cluster_name -g $resource_group_name -a $applicationgateway_name --appgw-id $appgwId

# Run demo app
kubectl apply -f https://raw.githubusercontent.com/Azure/application-gateway-kubernetes-ingress/master/docs/examples/aspnetapp.yaml

```

https://docs.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-existing#enable-the-agic-add-on-in-existing-aks-cluster-through-azure-cli





u

## Azure Monitor for Container 

[Overview of Container insights - Azure Monitor | Microsoft Docs](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview)

Container Insights collect metrics and logs on 

![image-20210811095324563](README.assets/image-20210811095324563.png)



![Container insights architecture](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/media/container-insights-overview/azmon-containers-architecture-01.png)



### Grafana dashboard tempalte

https://grafana.com/grafana/dashboards?dataSource=grafana-azure-monitor-datasource&category=docker



### Prometheus metrics integration

별도의 Prometheus 서버를 배포할 필요없이 Application 단에서 metrics endpoint를 노출하면 AKS monitoring agent가 해당 metric을 수집

![Container monitoring architecture for Prometheus](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/media/container-insights-prometheus-integration/monitoring-kubernetes-architecture.png)



## Azure Arc enabled Kubernetes (Preview) - Demo



Azure Monitor Container Insights supports monitoring Azure Arc enabled Kubernetes (preview).

- `Docker`, `Moby`, and CRI compatible container runtimes such `CRI-O` and `containerd`.

### Pre-requisite:

Create a k8s cluster (using kind (https://kind.sigs.k8s.io/) in this demo)

The following endpoints need to be enabled for outbound access in addition to the ones mentioned under [connecting a Kubernetes cluster to Azure Arc](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster#meet-network-requirements).

| Endpoint                       | Port |
| :----------------------------- | :--- |
| `*.ods.opinsights.azure.com`   | 443  |
| `*.oms.opinsights.azure.com`   | 443  |
| `dc.services.visualstudio.com` | 443  |
| `*.monitoring.azure.com`       | 443  |
| `login.microsoftonline.com`    | 443  |

```


# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo usermod -aG docker {username}
 
# install KIND
wget https://github.com/kubernetes-sigs/kind/releases/download/v0.11.1/kind-linux-amd64
chmod a+x kind-linux-amd64
sudo mv kind-linux-amd64 /usr/local/bin/kind
kind create cluster

# install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# install helm
wget https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz
tar xvzf helm-v3.6.3-linux-amd64.tar.gz
chmod a+x linux-amd64/helm
sudo mv linux-amd64/helm /usr/local/bin/
```

### Connect an existing Kubernetes cluster to Azure Arc

```bash
# make sure current kubeconfig file and context pointing to the target cluster
# install azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install the connectedk8s, k8s-extension Azure CLI extension
az extension add --name connectedk8s
az extension add --name k8s-extension

# login to azure
az login

# Register providers for Azure Arc enabled Kubernetes
az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ExtendedLocation

# Monitor the registration process
az provider show -n Microsoft.Kubernetes -o table
az provider show -n Microsoft.KubernetesConfiguration -o table
az provider show -n Microsoft.ExtendedLocation -o table

# create a resource group in which the k8s cluster will be included.
# For custom locations on your cluster, use East US or West Europe regions for now.
az group create --name AzureArcDemo --location EastUS --output table 

# Connect an existing Kubernetes cluster
az connectedk8s connect --name myKindCluster --resource-group AzureArcDemo

# deploying Azure Monitor Container Insights (preview) on the cluster
# https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-enable-arc-enabled-clusters?toc=/azure/azure-arc/kubernetes/toc.json

az k8s-extension create --name azuremonitor-containers \
	--cluster-name myKindCluster \
    --resource-group AzureArcDemo \
    --cluster-type connectedClusters \
    --extension-type Microsoft.AzureMonitor.Containers \
    --configuration-settings $loganalytics_workspace_id

```



### Ref) 



A. Encryption at Host (https://docs.microsoft.com/en-us/azure/aks/enable-host-encryption)


```bash
# To enable 'encryption at host', register the feature using CLI below.
az feature register --namespace "Microsoft.Compute" --name "EncryptionAtHost"

# wait until registered and invokoe below to get the change propagated
az provider register -n Microsoft.Compute
```

B. Using kubectl

```bash
# to install kubectl
sudo az aks install-cli

# to get k8s credential
az aks get-credentials -n $clustername -g $rg
```

C. Enabling Monitoring 

https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-enable-arc-enabled-clusters

```bash

az k8s-extension create --name azuremonitor-containers \
  --cluster-name $cluster_name \
  --resource-group $resource_group_name \
  --cluster-type connectedClusters \
  --extension-type Microsoft.AzureMonitor.Containers \
  --configuration-settings logAnalyticsWorkspaceResourceID=$loganalytics_workspace_id
```



Ref) 
https://docs.microsoft.com/en-us/azure/aks/monitor-aks?toc=/azure/azure-monitor/toc.json
