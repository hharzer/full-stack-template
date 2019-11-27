provider "azurerm" {
  /* TODO
  backend "azurerm" {
    resource_group_name  = "my-zone"
    storage_account_name = "myzone"
    container_name       = "my-zone-projects"
    key                  = "my-project-ENV"
  }
  */
}

/* Convert whitespace delimited strings into list(string) */
locals {
  taito_uptime_targets = (var.taito_uptime_targets == "" ? [] :
    split(" ", trimspace(replace(var.taito_uptime_targets, "/\\s+/", " "))))
  taito_uptime_paths = (var.taito_uptime_paths == "" ? [] :
    split(" ", trimspace(replace(var.taito_uptime_paths, "/\\s+/", " "))))
  taito_uptime_timeouts = (var.taito_uptime_timeouts == "" ? [] :
    split(" ", trimspace(replace(var.taito_uptime_timeouts, "/\\s+/", " "))))
}

module "azure-uptime" {
  source = "github.com/TaitoUnited/taito-terraform-modules//projects/azure-uptime"

  namespace             = var.taito_uptime_namespace_id
  project               = var.taito_project
  env                   = var.taito_env
  domain                = var.taito_domain

  uptime_targets        = local.taito_uptime_targets
  uptime_paths          = local.taito_uptime_paths
  uptime_timeouts       = local.taito_uptime_timeouts
}