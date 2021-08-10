# Azure Kubernetes Service (AKS) Hands-on Demo



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

### Azure Monitor 연동을 위해 아래 provider 등록이 필요

```bash
az provider show -n Microsoft.OperationsManagement -o table
az provider show -n Microsoft.OperationalInsights -o table

az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights
```



## AKS 생성하기 (Terraform) - Terraform

AKS 생성

Terraform 기반 

## AKS 생성하기 (Terraform) - Azure CLI

```bash
# define environmental variables
resource_group_name=deleteme-aksdemo2
location=koreacentral
vnet_name=myaksdemovnet
cluster_name=hyukdemo2
admin_username=azureuser
version=1.21.2
vm_size=Standard_D4s_v3

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
			 --network-plugin azure \
			 --network-policy calico \
			 --dns-service-ip 10.0.0.10 \
			 --docker-bridge-address 172.17.0.1/16 \
			 --outbound-type loadBalancer \
			 --service-cidr 10.0.0.0/16
```





모니터링

Azure 모니터링 구성 및 적용

멀티클러스터 환경에 적용법 (Azure arc)

AGW 적용 및 설명



1. Deploying 

## Monitoring

Ref) 
https://docs.microsoft.com/en-us/azure/aks/monitor-aks?toc=/azure/azure-monitor/toc.json
