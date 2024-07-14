# #############################################################################
# Production Schedule
# #############################################################################

# ------------------------------------------------------------------------------
# Production Schedule "Legacy Application"
# ------------------------------------------------------------------------------

resource "azurerm_storage_table" "production_schedule" {
  name                 = "ProductionSchedule"
  storage_account_name = azurerm_storage_account.global.name
}

locals {
  current_date = formatdate("YYYY-MM-DD", timestamp())
  core_ids = {
    0 = "ABC123"
    1 = "DEF456"
    2 = "GHI789"
    3 = "JKL987"
    4 = "MNO654"
    5 = "PQR321"
    6 = "STU159"
    7 = "VWX357"
    8 = "ZYA753"
    9 = "DCB951"
  }
}

resource "random_string" "finished_product_id" {
  length  = 10
  special = false
  upper   = true
}

resource "azurerm_storage_table_entity" "production_schedule_pod123" {
  count            = 10
  storage_table_id = azurerm_storage_table.production_schedule.id
  partition_key    = "pod123_${local.current_date}"
  row_key          = count.index + 1
  entity = {
    "PodId"    = "pod123",
    "Date"     = local.current_date,
    "Sequence" = count.index,
    "Model"    = "Model 3",
    "CoreId"   = local.core_ids[count.index],
    "FinishedProductId" = random_string.finished_product_id.result,
    "Status"   = "Scheduled",
  }
}

# ------------------------------------------------------------------------------
# Production Schedule Facade
# ------------------------------------------------------------------------------

module "production_schedule_facade" {
  source = "./modules/flex-function"

  app_configuration_id           = azurerm_app_configuration.remanufacturing.id
  app_insights_connection_string = azurerm_application_insights.remanufacturing.connection_string
  azure_environment              = var.azure_environment
  azure_region                   = var.azure_region
  function_app_name              = "ProductionScheduleFacade"
  key_vault_id                   = azurerm_key_vault.remanufacturing.id
  resource_group_name            = azurerm_resource_group.global.name
  resource_name_suffix           = var.resource_name_suffix
  storage_account_name           = "psf"
  tags                           = local.remanufacturing_tags
  app_settings                  = [
    {
      name  = "ServiceBusConnectionString",
      value = "service-bus-connection-string"
    },
    {
      name  = "OrderNextCore_TopicName",
      value = "order-next-core-topic-name"
    }
  ]
}