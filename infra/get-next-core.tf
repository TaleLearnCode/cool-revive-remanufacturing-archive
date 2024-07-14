# #############################################################################
# Get Next Core
# #############################################################################

# ------------------------------------------------------------------------------
# Get Next Core Service Bus Topic
# ------------------------------------------------------------------------------

resource "azurerm_servicebus_topic" "get_next_core" {
  name                      = "${module.service_bus_topic.name.abbreviation}-GetNextCore${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  namespace_id              = azurerm_servicebus_namespace.remanufacturing.id
  support_ordering          = true
  depends_on = [ 
    azurerm_servicebus_namespace.remanufacturing
   ]
}

resource "azurerm_app_configuration_key" "get_next_core_topic_name" {
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key                    = "ServiceBus:Topic:GetNextCore"
  label                  = var.azure_environment
  value                  = azurerm_servicebus_topic.get_next_core.name
}

# ------------------------------------------------------------------------------
# Get Next Core Function App
# ------------------------------------------------------------------------------

module "get_next_core_function_app" {
  source = "./modules/function-consumption"
  app_configuration_id           = azurerm_app_configuration.remanufacturing.id
  app_insights_connection_string = azurerm_application_insights.remanufacturing.connection_string
  azure_environment              = var.azure_environment
  azure_region                   = var.azure_region
  function_app_name              = "GetNextCore"
  key_vault_id                   = azurerm_key_vault.remanufacturing.id
  resource_group_name            = azurerm_resource_group.global.name
  resource_name_suffix           = var.resource_name_suffix
  storage_account_name           = "psf"
  tags                           = local.remanufacturing_tags
  #app_settings = {
  #  "GetNextCoreTopicName" = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.get_next_core_topic_name.key}; Label=${azurerm_app_configuration_key.get_next_core_topic_name.label})",
  #}
  app_settings = {
    "GetNextCoreTopicName"       = azurerm_servicebus_topic.get_next_core.name
  }

}