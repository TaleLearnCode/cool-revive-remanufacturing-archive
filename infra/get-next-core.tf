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
  lifecycle {
    ignore_changes = [configuration_store_id]
  }
}

resource "azurerm_servicebus_topic_authorization_rule" "get_next_core_sender" {
  name     = "GetNextCoreSender"
  topic_id = azurerm_servicebus_topic.get_next_core.id
  listen   = false
  send     = true
  manage   = false
}

module "get_next_core_sender_connection_string" {
  source                 = "./modules/app-config-secret"
  app_config_label       = var.azure_environment
  app_config_key         = "ServiceBus:Topic:GetNextCore:SenderConnectionString"
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key_vault_id           = azurerm_key_vault.remanufacturing.id
  secret_name            = "ServiceBus-Topic-GetNextCore-SenderConnectionString"
  secret_value            = azurerm_servicebus_topic_authorization_rule.get_next_core_sender.primary_connection_string
}

resource "azurerm_servicebus_topic_authorization_rule" "get_next_core_listener" {
  name     = "GetNextCoreListener"
  topic_id = azurerm_servicebus_topic.get_next_core.id
  listen   = true
  send     = false
  manage   = false
}

module "get_next_core_listener_connection_string" {
  source                 = "./modules/app-config-secret"
  app_config_label       = var.azure_environment
  app_config_key         = "ServiceBus:Topic:GetNextCore:ListenerConnectionString"
  configuration_store_id = azurerm_app_configuration.remanufacturing.id
  key_vault_id           = azurerm_key_vault.remanufacturing.id
  secret_name            = "ServiceBus-Topic-GetNextCore-ListenerConnectionString"
  secret_value            = azurerm_servicebus_topic_authorization_rule.get_next_core_sender.primary_connection_string
}

resource "azurerm_servicebus_subscription" "get_next_core" {
  name               = "${module.service_bus_topic_subscription.name.abbreviation}-GetNextCore-${var.azure_environment}-${module.azure_regions.region.region_short}"
  topic_id           = azurerm_servicebus_topic.get_next_core.id
  max_delivery_count = 10
}

#resource "azurerm_servicebus_subscription_rule" "get_next_core_pod123" {
#  name            = "${module.service_bus_topic_subscription.name.abbreviation}-GetNextCore_Pod123-${var.azure_environment}-${module.azure_regions.region.region_short}"
#  subscription_id = azurerm_servicebus_subscription.get_next_core.id
#  filter_type     = "SqlFilter"
#  sql_filter      = "PodId='Pod123'"
#}

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
  resource_group_name            = azurerm_resource_group.remanufacturing.name
  resource_name_suffix           = var.resource_name_suffix
  storage_account_name           = "gnc"
  tags                           = local.remanufacturing_tags
  #app_settings = {
  #  "ServiceBusConnectionString" = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.get_next_core_topic_name.key}; Label=${azurerm_app_configuration_key.get_next_core_topic_name.label})",
  #  "GetNextCoreTopicName" = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.get_next_core_topic_name.key}; Label=${azurerm_app_configuration_key.get_next_core_topic_name.label})",
  #}
  app_settings = {
    "ServiceBusConnectionString" = azurerm_servicebus_topic_authorization_rule.get_next_core_sender.primary_connection_string
    "GetNextCoreTopicName"       = azurerm_servicebus_topic.get_next_core.name
  }
  depends_on = [ azurerm_resource_group.remanufacturing ]
}

# ------------------------------------------------------------------------------
# Get Next Core Handler Function App
# ------------------------------------------------------------------------------

module "get_next_core_handler_function_app" {
  source = "./modules/function-consumption"
  app_configuration_id           = azurerm_app_configuration.remanufacturing.id
  app_insights_connection_string = azurerm_application_insights.remanufacturing.connection_string
  azure_environment              = var.azure_environment
  azure_region                   = var.azure_region
  function_app_name              = "GetNextCoreHandler"
  key_vault_id                   = azurerm_key_vault.remanufacturing.id
  resource_group_name            = azurerm_resource_group.remanufacturing.name
  resource_name_suffix           = var.resource_name_suffix
  storage_account_name           = "gnch"
  tags                           = local.remanufacturing_tags
  #app_settings = {
  #  "ServiceBusConnectionString" = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.get_next_core_topic_name.key}; Label=${azurerm_app_configuration_key.get_next_core_topic_name.label})",
  #  "GetNextCoreTopicName" = "@Microsoft.AppConfiguration(Endpoint=${azurerm_app_configuration.remanufacturing.endpoint}; Key=${azurerm_app_configuration_key.get_next_core_topic_name.key}; Label=${azurerm_app_configuration_key.get_next_core_topic_name.label})",
  #}
  app_settings = {
    "ServiceBusConnectionString" = azurerm_servicebus_topic_authorization_rule.get_next_core_listener.primary_connection_string
    "OrderNextCoreTopicName"       = azurerm_servicebus_topic.get_next_core.name
  }
  depends_on = [ azurerm_resource_group.remanufacturing ]
}