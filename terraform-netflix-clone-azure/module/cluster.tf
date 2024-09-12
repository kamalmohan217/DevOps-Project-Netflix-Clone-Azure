#############################################################################################################################
# Provision AKS Cluster
#############################################################################################################################

# Create Resource Group
resource "azurerm_resource_group" "aks_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "insights" {
  name                = "${var.prefix}-log-analytics-workspace"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  retention_in_days   = 30
}

# Manage a Log Analytics Solutions
resource "azurerm_log_analytics_solution" "container_insight" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.aks_rg.location
  resource_group_name   = azurerm_resource_group.aks_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.insights.id
  workspace_name        = azurerm_log_analytics_workspace.insights.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# Create VNet for AKS
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  address_space       = ["10.224.0.0/12"]
}

# Create Subnet for VNet of AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "default"         ###"${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.Storage"]
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.224.0.0/16"]
  depends_on = [azurerm_virtual_network.aks_vnet]
}

# Create Subnet for VNet of Application Gateway
resource "azurerm_subnet" "appgtw_subnet" {
  name                 = "subnet-1"         ###"${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
#  service_endpoints    = ["Microsoft.ContainerRegistry", "Microsoft.Storage"]
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.225.0.0/16"]
  depends_on = [azurerm_virtual_network.aks_vnet]
}

# Create Subnet for PostgreSQL Flexible servers
resource "azurerm_subnet" "postgresql_flexible_server_subnet" {
  name                 = "${var.prefix}-postgresql-flexible-server-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.227.0.0/16"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "postgres-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Create Public IP for Application Gateway
resource "azurerm_public_ip" "appgtw_public_ip" {
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  allocation_method   = "Static"  ### Select in between Static and Dynamic

  sku = "Standard"   ### Basic, For Availability Zone to be Enabled the SKU of Public IP must be Standard  
  zones = [1, 2, 3]

  tags = {
    Environment = var.env
  }
}

# Generate random string of byte length 16
resource "random_id" "id1" {
  byte_length = 16
}

# Generate random string of byte lengh 8
resource "random_id" "id2" {
  byte_length = 8
}

# Create private dns zone
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "${random_id.id1.hex}.privatelink.eastus2.azmk8s.io"
  resource_group_name = azurerm_resource_group.aks_rg.name
}

# Create virtual network link
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "${var.prefix}-cluster-dns-${random_id.id2.hex}"
  resource_group_name   = azurerm_resource_group.aks_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.aks_vnet.id
}

# Create user assigned identity
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-aks-uai"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
}

# Identity role assignment
resource "azurerm_role_assignment" "dns_contributor" {
  scope                = azurerm_private_dns_zone.private_dns_zone.id
  role_definition_name = "Contributor"   ### "Private DNS Zone Contributor" Role can also be assigned
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_vnet_subnet" {
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
  role_definition_name = "Contributor"     ### "Network Contributor" Role can also be assigned
  scope                = azurerm_subnet.aks_subnet.id
#  depends_on = [azurerm_monitor_metric_alert.alert_rule1, azurerm_monitor_metric_alert.alert_rule2]
}

# Identity role assignment for Application Gareway 
resource "azurerm_role_assignment" "agw" {
  scope                = azurerm_application_gateway.appgtw.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on = [azurerm_application_gateway.appgtw, azurerm_kubernetes_cluster.aks_cluster]

}

# Identity role assignment for Resource Group
resource "azurerm_role_assignment" "rg" {
  scope                = azurerm_resource_group.aks_rg.id
  role_definition_name = "Contributor"       ###Reader permission can be assigned
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on = [azurerm_application_gateway.appgtw, azurerm_kubernetes_cluster.aks_cluster]
}

# Create Azure Application Gateway 
resource "azurerm_application_gateway" "appgtw" {
  name                = "app-gtw-ingress-controller"           ###var.appgtw_name
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = azurerm_subnet.appgtw_subnet.id
  }

  frontend_port {
    name = "${azurerm_virtual_network.aks_vnet.name}-feport"
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${azurerm_virtual_network.aks_vnet.name}-feip-public"
    public_ip_address_id = azurerm_public_ip.appgtw_public_ip.id
  }

  frontend_ip_configuration {
    name                          = "${azurerm_virtual_network.aks_vnet.name}-feip-private"
    private_ip_address            = "10.225.0.4"
    private_ip_address_allocation = "Static"
    subnet_id                     = azurerm_subnet.appgtw_subnet.id
  }

  backend_address_pool {
    name = "${azurerm_virtual_network.aks_vnet.name}-beap"
  }

  backend_http_settings {
    name                  = "${azurerm_virtual_network.aks_vnet.name}-be-htst"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "${azurerm_virtual_network.aks_vnet.name}-httplstn"
    frontend_ip_configuration_name = "${azurerm_virtual_network.aks_vnet.name}-feip-public"
    frontend_port_name             = "${azurerm_virtual_network.aks_vnet.name}-feport"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${azurerm_virtual_network.aks_vnet.name}-rqrt"
    rule_type                  = "Basic"
    http_listener_name         = "${azurerm_virtual_network.aks_vnet.name}-httplstn"
    backend_address_pool_name  = "${azurerm_virtual_network.aks_vnet.name}-beap"
    backend_http_settings_name = "${azurerm_virtual_network.aks_vnet.name}-be-htst"
    priority                   = 1
  }

  tags = {
    Environment = var.env
  }

  depends_on = [azurerm_subnet.appgtw_subnet]
}

# Create Azure Kubernetes Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.prefix}-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "${var.prefix}-cluster-dns"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.prefix}-noderg"
  sku_tier            = "Standard"
  private_cluster_enabled = true
  azure_policy_enabled = true
  private_dns_zone_id = azurerm_private_dns_zone.private_dns_zone.id
  
  default_node_pool {
    name                 = "agentpool"
    vm_size              = "Standard_B2ms"      ###Standard_B2s       ###Standard_DS2_v2
    orchestrator_version = var.kubernetes_version
    zones                = [1, 2, 3]
#    enable_node_public_ip = true             ###  Will be used in Public AKS Cluster.
    auto_scaling_enabled = true
    max_count            = 1
    min_count            = 1
    max_pods             = 110
    os_disk_type         = "Managed"
    os_disk_size_gb      = 30
    os_sku               = "Ubuntu"    ### You can select between Ubuntu and AzureLinux.
    type                 = "VirtualMachineScaleSets"
    vnet_subnet_id       = azurerm_subnet.aks_subnet.id
    upgrade_settings {
      max_surge = "10%"
    }
    node_labels = {
      "nodepool-type"    = "system"
      "environment"      = var.env
      "nodepoolos"       = "linux"
#      "app"              = "system-apps" 
    } 
    tags = {
      "nodepool-type"    = "system"
      "environment"      = var.env
      "nodepoolos"       = "linux"
#      "app"              = "system-apps" 
    } 
  }

  automatic_upgrade_channel = "stable"
  node_os_upgrade_channel   = "NodeImage"
  maintenance_window_auto_upgrade {
      frequency   = "RelativeMonthly"
      interval    = 1
      duration    = 4
      day_of_week = "Sunday"
      week_index  = "First"
      start_time  = "00:00"
#      utc_offset = "+05:30"
  }
  maintenance_window_node_os {
      frequency   = "Weekly"
      interval    = 1
      duration    = 4
      day_of_week = "Sunday"
      start_time  = "00:00"
#      utc_offset = "+05:30"
  }


# Identity (System Assigned or Service Principal)
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }
#  identity {
#    type = "SystemAssigned"
#  }

### Storage Profile Block
  storage_profile {
    blob_driver_enabled = false                   ### Provide the boolean to enable or disable the Blob CSI Driver. Default value is false.
    disk_driver_enabled = true                    ### Provide the boolean to enable or disable the Disk CSI Driver. Default value is true.
    #disk_driver_version = "v1"                    ### Disk driver version v2 is in public review. Default version is v1.
    file_driver_enabled = true                    ### Provide the boolean to enable or disable the File CSI Driver. Default value is true.
    snapshot_controller_enabled = true            ### Provide the boolean to enable or disable the Snapshot Controller. Default value is true.
  }


### Linux Profile
#  linux_profile {
#    admin_username = "ritesh"
#    ssh_key {
#      key_data = file(var.ssh_public_key)
#    }
#  }

# Network Profile
  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    load_balancer_sku = "standard"
    service_cidr        = "10.0.0.0/16"  ### Kubernetes service address range
    dns_service_ip      = "10.0.0.10"    ### Kubernetes DNS service IP address
  }

  monitor_metrics {

  }

  oms_agent {
#    enabled =  true
    log_analytics_workspace_id = azurerm_log_analytics_workspace.insights.id
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.appgtw.id
  }

  tags = {
    Environment = var.env
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "autoscale_node_pool" {
# count                        = var.enable_auto_scaling ? 1 : 0
  name                         = "userpool"
  kubernetes_cluster_id        = azurerm_kubernetes_cluster.aks_cluster.id
  zones                        = [1, 2, 3]
  orchestrator_version = var.kubernetes_version
  vm_size                      = "Standard_B2ms"                ###Standard_B2s
  mode                         = "User"          ### You can select between System and User
# enable_node_public_ip = true             ###  Will be used in Public AKS Cluster.
  auto_scaling_enabled = true
  max_count            = 1
  min_count            = 1
  max_pods             = 110
  os_disk_type         = "Managed"
  os_disk_size_gb      = 30  
  os_type              = "Linux"
  os_sku               = "Ubuntu"        ### You can select between Ubuntu and AzureLinux.
#  type                 = "VirtualMachineScaleSets"
  vnet_subnet_id       = azurerm_subnet.aks_subnet.id
  upgrade_settings {
    max_surge = "10%"
  }
  node_labels = {
    "nodepool-type"    = "User"
    "environment"      = var.env
    "nodepoolos"       = "linux"
#   "app"              = "system-apps"
  }
  tags = {
    "nodepool-type"    = "User"
    "environment"      = var.env
    "nodepoolos"       = "linux"
#   "app"              = "system-apps"
  }
} 

##########################################################################################################################################

resource "azurerm_monitor_action_group" "action_group" {
  name                = "${var.prefix}-action-group"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = "global"
  short_name          = var.action_group_shortname

  email_receiver {
    name          = "GroupNotification"
    email_address = "singhriteshkumar251@gmail.com"
  }
}

resource "azurerm_monitor_metric_alert" "alert_rule1" {
  name                = "${var.prefix}-alert-rule1"
  resource_group_name = azurerm_resource_group.aks_rg.name
  scopes              = [azurerm_kubernetes_cluster.aks_cluster.id]
  description         = "Action will be triggered when Percentage CPU Utilization is greater than 0."
  auto_mitigate       = true    ### Metric Alert to be auto resolved
  frequency           = "PT5M"


  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
   
  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

resource "azurerm_monitor_metric_alert" "alert_rule2" {
  name                = "${var.prefix}-alert-rule2"
  resource_group_name = azurerm_resource_group.aks_rg.name
  scopes              = [azurerm_kubernetes_cluster.aks_cluster.id]
  auto_mitigate       = true    ### Metric Alert to be auto resolved
  frequency           = "PT5M"
  
  criteria {
    aggregation      = "Average"
    metric_name      = "node_memory_working_set_percentage"
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    operator         = "GreaterThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group.id
  }
}

#######################################################################################################
# Create Kubeconfig file 
#######################################################################################################

resource "null_resource" "kubectl" {
    provisioner "local-exec" {
        command = "az account set --subscription $(az account show --query id|tr -d '\"') && az aks get-credentials --resource-group ${azurerm_resource_group.aks_rg.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name} --overwrite-existing && chmod 600 ~/.kube/config"
        interpreter = ["/bin/bash", "-c"]
    }

    depends_on = [azurerm_kubernetes_cluster.aks_cluster, azurerm_kubernetes_cluster_node_pool.autoscale_node_pool]
}

#######################################################################################################
# Authorization for VNet Subnet
#######################################################################################################

#resource "azurerm_role_assignment" "aks_vnet_subnet2" {
#  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
#  role_definition_name = "Contributor"
#  scope                = azurerm_subnet.aks_subnet.id
#  depends_on = [azurerm_monitor_metric_alert.alert_rule1, azurerm_monitor_metric_alert.alert_rule2]
#}

