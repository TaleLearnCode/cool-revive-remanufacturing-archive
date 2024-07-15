# ##############################################################################
# Order Next Core
# ##############################################################################

# ------------------------------------------------------------------------------
# Order Next Core Service Bus Topic
# ------------------------------------------------------------------------------

resource "azurerm_servicebus_topic" "order_next_core" {
  name                      = "${module.service_bus_topic.name.abbreviation}-OrderNextCore${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  namespace_id              = azurerm_servicebus_namespace.remanufacturing.id
  support_ordering          = true
  depends_on = [ 
    azurerm_servicebus_namespace.remanufacturing
   ]
}

resource "azurerm_app_configuration_key" "order_next_core_topic_name" {
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key                    = "ServiceBus:Topic:OrderNextCore"
  label                  = var.azure_environment
  value                  = azurerm_servicebus_topic.order_next_core.name
  lifecycle {
    ignore_changes = [configuration_store_id]
  }
}

resource "azurerm_servicebus_topic_authorization_rule" "order_next_core_sender" {
  name     = "OrderNextCoreSender"
  topic_id = azurerm_servicebus_topic.get_next_core.id
  listen   = false
  send     = true
  manage   = false
}

module "order_next_core_sender_connection_string" {
  source                 = "./modules/app-config-secret"
  app_config_label       = var.azure_environment
  app_config_key         = "ServiceBus:Topic:OrderNextCore:SenderConnectionString"
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key_vault_id           = azurerm_key_vault.remanufacturing.id
  secret_name            = "ServiceBus-Topic-OrderNextCore-SenderConnectionString"
  secret_value            = azurerm_servicebus_topic_authorization_rule.order_next_core_sender.primary_connection_string
}

resource "azurerm_servicebus_topic_authorization_rule" "order_next_core_listener" {
  name     = "GetNextCoreListener"
  topic_id = azurerm_servicebus_topic.order_next_core.id
  listen   = true
  send     = false
  manage   = false
}

module "order_next_core_listener_connection_string" {
  source                 = "./modules/app-config-secret"
  app_config_label       = var.azure_environment
  app_config_key         = "ServiceBus:Topic:OrderNextCore:ListenerConnectionString"
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key_vault_id           = azurerm_key_vault.remanufacturing.id
  secret_name            = "ServiceBus-Topic-OrderNextCore-ListenerConnectionString"
  secret_value            = azurerm_servicebus_topic_authorization_rule.order_next_core_sender.primary_connection_string
}

resource "azurerm_servicebus_subscription" "order_next_core" {
  name               = "${module.service_bus_topic_subscription.name.abbreviation}-OrderNextCore-${var.azure_environment}-${module.azure_regions.region.region_short}"
  topic_id           = azurerm_servicebus_topic.get_next_core.id
  max_delivery_count = 10
}