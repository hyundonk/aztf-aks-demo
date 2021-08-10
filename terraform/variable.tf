variable "cluster_name" {}
variable "resource_group_name" {}

variable "location" {
  default = "koreacentral"
}

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

variable "admin_username" {
  default = "azureuser"
}

variable "cluster_version" {
  default = "1.21.2"
}

variable "vm_size" {
  default = "Standard_D4s_v3"
}

variable "bastion"       {}


