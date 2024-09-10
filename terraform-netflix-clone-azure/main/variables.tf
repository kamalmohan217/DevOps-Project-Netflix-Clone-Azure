variable "prefix" {
  type = string
  description = "Provide the Prefix Name" 
}

variable "location" {
  type = list
  description = "Provide the Location for Azure Resource to be created"
}

variable "kubernetes_version" {
  type = list
  description = "Provide the Kubernetes Version"
}

variable "ssh_public_key" {
  type = string
  description = "Provide the file name which keep the ssh public key"
}

variable "action_group_shortname" {
  type = string
  description = "Provide the short name for Azure Action Group"
}

variable "env" {
  type = list
  description = "Provide the Environment for AKS Cluster"
}

################################################################# Variables for Azure VM ##############################################################

variable "vm_size" {
  type = list
  description = "Provide the Size of the Azure VM"
}

variable "availability_zone" {
  type = list
  description = "Provide the Availability Zone into which the VM to be created"
}

variable "static_dynamic" {
  type = list
  description = "Select the Static or Dynamic"
}

variable "disk_size_gb" {
  type = number
  description = "Provide the Disk Size in GB"
}

variable "extra_disk_size_gb" {
  type = number
  description = "Provide the Size of Extra Disk to be Attached"
}

variable "computer_name" {
  type = string
  description = "Provide the Hostname"
}

variable "admin_username" {
  type = string
  description = "Provid the Administrator Username"
}

variable "admin_password" {
  type = string
  description = "Provide the Administrator Password"
}

################################################### Variables to create Azure Container Registry ######################################################

variable "acr_sku" {
  type = list
  description = "Selection the SKU among Basic, Standard and Premium"
}

variable "admin_enabled" {
  type = bool
  description = "The ACR accessibility is Admin enabled or not."
}
