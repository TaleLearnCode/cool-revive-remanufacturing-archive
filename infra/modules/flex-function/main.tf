# #############################################################################
# Required Providers
# #############################################################################

terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
    }
  }
}

# #############################################################################
# Referenced Resources
# #############################################################################

data "azurerm_resource_group" "function_app_rg" {
  name = var.resource_group_name
}

data "azurerm_linux_function_app" "new_function_app" {
  name                = azapi_resource.function_app.name
  resource_group_name = data.azurerm_resource_group.function_app_rg.name
}

# #############################################################################
# App Service Plan (server farm)
# #############################################################################

resource "azapi_resource" "app_service_plan" {
  type                      = "Microsoft.Web/serverfarms@2023-12-01"
  schema_validation_enabled = false
  location                  = data.azurerm_resource_group.function_app_rg.location
  name                      = "${module.app_service_plan.name.abbreviation}-${var.function_app_name}${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id                 = data.azurerm_resource_group.function_app_rg.id
  body                      = jsonencode({
    kind = "functionapp",
    sku = {
      tier = "FlexConsumption",
      name = "FC1"
    },
    properties = {
      reserved = true
    }
  })
}

# #############################################################################
# Storage Account
# #############################################################################

resource "azurerm_storage_account" "function_storage" {
  name                     = lower("${module.storage_account.name.abbreviation}${var.storage_account_name}${var.resource_name_suffix}${var.azure_environment}${module.azure_regions.region.region_short}")
  resource_group_name      = data.azurerm_resource_group.function_app_rg.name
  location                 = data.azurerm_resource_group.function_app_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_storage_container" "deployment_package" {
  name                  = "deploymentpackage"
  storage_account_name  = azurerm_storage_account.function_storage.name
  container_access_type = "private"
}

locals {
  blob_storage_and_container = "${azurerm_storage_account.function_storage.primary_blob_endpoint}deploymentpackage"
}

# #############################################################################
# Function App
# #############################################################################

resource "azapi_resource" "function_app" {
  type                      = "Microsoft.Web/sites@2023-12-01"
  schema_validation_enabled = false
  location                  = data.azurerm_resource_group.function_app_rg.location
  name                      = "${module.function_app.name.abbreviation}-${var.function_app_name}${var.resource_name_suffix}-${var.azure_environment}-${module.azure_regions.region.region_short}"
  parent_id                 = data.azurerm_resource_group.function_app_rg.id
  body                      = jsonencode({
    kind = "functionapp,linux",
    identity = {
      type = "SystemAssigned"
    },
    properties = {
      serverFarmId = azapi_resource.app_service_plan.id,
      functionAppConfig = {
        deployment = {
          storage = {
            type  = "blobContainer",
            value = local.blob_storage_and_container,
            authentication = {
              type = "SystemAssignedIdentity"
            }
          }
        },
        scaleAndConcurrency = {
          maximumInstanceCount = var.max_instance_count,
          instanceMemoryMB     = var.instance_memory
        },
        runtime = {
          name    = "dotnet-isolated",
          version = "8.0"
        }
      },
      siteConfig = {
        appSettings = concat([
          {
            name  = "AzureWebJobsStorage__accountName",
            value = azurerm_storage_account.function_storage.name
          },
          {
            name  = "APPLICATIONINSIGHTS_CONNECTION_STRING",
            value = var.app_insights_connection_string
          }
        ], var.app_settings)
      }
    }
  })
  depends_on = [
    azapi_resource.app_service_plan,
    azurerm_storage_account.function_storage,
    azurerm_storage_container.deployment_package
  ]
}

# #############################################################################
# Role Assignments
# #############################################################################

resource "azurerm_role_assignment" "storage_blob_data_owner" {
  scope                = azurerm_storage_account.function_storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_linux_function_app.new_function_app.identity.0.principal_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_linux_function_app.new_function_app.identity.0.principal_id
}

resource "azurerm_role_assignment" "app_configuration_data_owner" {
  scope                = var.app_configuration_id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = data.azurerm_linux_function_app.new_function_app.identity.0.principal_id
}