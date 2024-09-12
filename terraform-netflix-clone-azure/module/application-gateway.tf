###################################### Azure Application Gateway for SonarQube ###############################################

resource "azurerm_public_ip" "public_ip_gateway_sonarqube" {
  name                = "vmss-public-ip-sonarqube"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = "Standard"   ### You can select between Basic and Standard.
  allocation_method   = "Static"     ### You can select between Static and Dynamic.
}

resource "azurerm_application_gateway" "application_gateway_sonarqube" {
  name                = "${var.prefix}-application-gateway-sonarqube"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
#   capacity = 2
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 3
  }

  gateway_ip_configuration {
    name      = "sonarqube-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgtw_subnet.id
  }

  frontend_port {
    name = "${var.prefix}-gateway-subnet-feport-sonarqube"
    port = 80
  }

  frontend_port {
    name = "${var.prefix}-gateway-subnet-feporthttps-sonarqube"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${var.prefix}-gateway-subnet-feip-sonarqube"
    public_ip_address_id = azurerm_public_ip.public_ip_gateway_sonarqube.id
  }

  backend_address_pool {
    name = "${var.prefix}-gateway-subnet-beap-sonarqube"
    ip_addresses = [azurerm_network_interface.vnet_interface_sonarqube.private_ip_address]
  }

  backend_http_settings {
    name                  = "${var.prefix}-gateway-subnet-be-htst-sonarqube"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 9000
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "${var.prefix}-gateway-subnet-be-probe-app1-sonarqube"
  }

  probe {
    name                = "${var.prefix}-gateway-subnet-be-probe-app1-sonarqube"
    host                = "sonarqube.singhritesh85.com"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 9000
    path                = "/"
  }

  http_listener {
    name                           = "${var.prefix}-gateway-subnet-httplstn-sonarqube"
    frontend_ip_configuration_name = "${var.prefix}-gateway-subnet-feip-sonarqube"
    frontend_port_name             = "${var.prefix}-gateway-subnet-feport-sonarqube"
    protocol                       = "Http"
  }

  # HTTP Routing Rule - HTTP to HTTPS Redirect
  request_routing_rule {
    name                       = "${var.prefix}-gateway-subnet-rqrt-sonarqube"
    priority                   = 101
    rule_type                  = "Basic"
    http_listener_name         = "${var.prefix}-gateway-subnet-httplstn-sonarqube"
#    backend_address_pool_name  = "${var.prefix}-gateway-subnet-beap-sonarqube"  ###  It should not be used when redirection of HTTP to HTTPS is configured.
#    backend_http_settings_name = "${var.prefix}-gateway-subnet-be-htst-sonarqube"   ###  It should not be used when redirection of HTTP to HTTPS is configured.
    redirect_configuration_name = "${var.prefix}-gateway-subnet-rdrcfg-sonarqube"
  }

  # Redirect Config for HTTP to HTTPS Redirect
  redirect_configuration {
    name = "${var.prefix}-gateway-subnet-rdrcfg-sonarqube"
    redirect_type = "Permanent"
    target_listener_name = "${var.prefix}-lstn-https-sonarqube"    ### "${var.prefix}-gateway-subnet-httplstn"
    include_path = true
    include_query_string = true
  }

  # SSL Certificate Block
  ssl_certificate {
    name = "${var.prefix}-certificate"
    password = "Dexter@123"
    data = filebase64("mykey.pfx")
  }

  # HTTPS Listener - Port 443
  http_listener {
    name                           = "${var.prefix}-lstn-https-sonarqube"
    frontend_ip_configuration_name = "${var.prefix}-gateway-subnet-feip-sonarqube"
    frontend_port_name             = "${var.prefix}-gateway-subnet-feporthttps-sonarqube"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.prefix}-certificate"
  }

  # HTTPS Routing Rule - Port 443
  request_routing_rule {
    name                       = "${var.prefix}-rqrt-https-sonarqube"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "${var.prefix}-lstn-https-sonarqube"
    backend_address_pool_name  = "${var.prefix}-gateway-subnet-beap-sonarqube"
    backend_http_settings_name = "${var.prefix}-gateway-subnet-be-htst-sonarqube"
  }

}

###################################### Azure Application Gateway for Grafana ###############################################

resource "azurerm_public_ip" "public_ip_gateway_grafana" {
  name                = "vmss-public-ip-grafana"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = "Standard"   ### You can select between Basic and Standard.
  allocation_method   = "Static"     ### You can select between Static and Dynamic.
}

resource "azurerm_application_gateway" "application_gateway_grafana" {
  name                = "${var.prefix}-application-gateway-grafana"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
#   capacity = 2
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 3
  }

  gateway_ip_configuration {
    name      = "grafana-gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgtw_subnet.id
  }

  frontend_port {
    name = "${var.prefix}-gateway-subnet-feport-grafana"
    port = 80
  }

  frontend_port {
    name = "${var.prefix}-gateway-subnet-feporthttps-grafana"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${var.prefix}-gateway-subnet-feip-grafana"
    public_ip_address_id = azurerm_public_ip.public_ip_gateway_grafana.id
  }

  backend_address_pool {
    name = "${var.prefix}-gateway-subnet-beap-grafana"
    ip_addresses = [azurerm_network_interface.vnet_interface_grafana.private_ip_address]
  }

  backend_http_settings {
    name                  = "${var.prefix}-gateway-subnet-be-htst-grafana"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 3000
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "${var.prefix}-gateway-subnet-be-probe-app1-grafana"
  }

  probe {
    name                = "${var.prefix}-gateway-subnet-be-probe-app1-grafana"
    host                = "grafana.singhritesh85.com"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 3000
    path                = "/"
  }

  http_listener {
    name                           = "${var.prefix}-gateway-subnet-httplstn-grafana"
    frontend_ip_configuration_name = "${var.prefix}-gateway-subnet-feip-grafana"
    frontend_port_name             = "${var.prefix}-gateway-subnet-feport-grafana"
    protocol                       = "Http"
  }

  # HTTP Routing Rule - HTTP to HTTPS Redirect
  request_routing_rule {
    name                       = "${var.prefix}-gateway-subnet-rqrt-grafana"
    priority                   = 101
    rule_type                  = "Basic"
    http_listener_name         = "${var.prefix}-gateway-subnet-httplstn-grafana"
#    backend_address_pool_name  = "${var.prefix}-gateway-subnet-beap-grafana"  ###  It should not be used when redirection of HTTP to HTTPS is configured.
#    backend_http_settings_name = "${var.prefix}-gateway-subnet-be-htst-grafana"   ###  It should not be used when redirection of HTTP to HTTPS is configured.
    redirect_configuration_name = "${var.prefix}-gateway-subnet-rdrcfg-grafana"
  }

  # Redirect Config for HTTP to HTTPS Redirect
  redirect_configuration {
    name = "${var.prefix}-gateway-subnet-rdrcfg-grafana"
    redirect_type = "Permanent"
    target_listener_name = "${var.prefix}-lstn-https-grafana"    ### "${var.prefix}-gateway-subnet-httplstn"
    include_path = true
    include_query_string = true
  }

  # SSL Certificate Block
  ssl_certificate {
    name = "${var.prefix}-certificate"
    password = "Dexter@123"
    data = filebase64("mykey.pfx")
  }

  # HTTPS Listener - Port 443
  http_listener {
    name                           = "${var.prefix}-lstn-https-grafana"
    frontend_ip_configuration_name = "${var.prefix}-gateway-subnet-feip-grafana"
    frontend_port_name             = "${var.prefix}-gateway-subnet-feporthttps-grafana"
    protocol                       = "Https"
    ssl_certificate_name           = "${var.prefix}-certificate"
  }

  # HTTPS Routing Rule - Port 443
  request_routing_rule {
    name                       = "${var.prefix}-rqrt-https-grafana"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "${var.prefix}-lstn-https-grafana"
    backend_address_pool_name  = "${var.prefix}-gateway-subnet-beap-grafana"
    backend_http_settings_name = "${var.prefix}-gateway-subnet-be-htst-grafana"
  }

}
