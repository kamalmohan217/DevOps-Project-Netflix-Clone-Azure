resource "azurerm_private_dns_zone" "sonarqube_private_postgresql" {
  name                = "sonarqube-postgresql3.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.aks_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sonarqube_postgresql_vnet_link" {
  name                  = "sonarqubeprivate.com"
  private_dns_zone_name = azurerm_private_dns_zone.sonarqube_private_postgresql.name
  virtual_network_id    = azurerm_virtual_network.aks_vnet.id
  resource_group_name   = azurerm_resource_group.aks_rg.name
  depends_on            = [azurerm_subnet.postgresql_flexible_server_subnet]
}

resource "azurerm_postgresql_flexible_server" "azure_postgresql" {
  name                          = "sonarqube-postgresql3"
  resource_group_name           = azurerm_resource_group.aks_rg.name
  location                      = azurerm_resource_group.aks_rg.location
  version                       = "14"
  delegated_subnet_id           = azurerm_subnet.postgresql_flexible_server_subnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.sonarqube_private_postgresql.id
  public_network_access_enabled = false
  administrator_login           = "postgres"
  administrator_password        = "Admin123"
  zone                          = "1"

#  high_availability {
#    mode = "ZoneRedundant"
#    standby_availability_zone = 2
#  } 

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.sonarqube_postgresql_vnet_link, null_resource.kubectl]

}
