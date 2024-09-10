output "acr_login_server" {
  description = "The URL of the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server         #azurerm_container_registry.acr.*.login_server
}
