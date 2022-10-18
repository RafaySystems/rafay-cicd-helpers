module "project" {
  source      =  "./modules/project"
  project     = var.project
}

module "cloud_credentials" {
  source                  = "./modules/cloud_credentials"
  cloud_credentials_name  = var.cloud_credentials_name
  project                 = var.project
  client_id               = var.client_id
  client_secret           = var.client_secret
  subscription_id         = var.subscription_id
  tenant_id               = var.tenant_id
  depends_on              = [ module.project]
}

module "repositories" {
  source               = "./modules/repositories"
  project              = var.project
  public_repositories  = var.public_repositories
  depends_on           = [ module.project]
}

module "addons" {
  source               = "./modules/addons"
  project              = var.project
  infra_addons         = var.infra_addons
  depends_on           = [ module.repositories]
}

module "cluster-overrides" {
  source               = "./modules/cluster-overrides"
  project              = var.project
  cluster_name         = var.cluster_name
  overrides_config     = var.overrides_config
  depends_on           = [ module.addons]
}

module "blueprint" {
  source                 = "./modules/blueprints"
  project                = var.project
  blueprint_name         = var.blueprint_name
  blueprint_version      = var.blueprint_version
  base_blueprint         = var.base_blueprint
  base_blueprint_version = var.base_blueprint_version
  custom_addon_1         = var.custom_addon_1
  custom_addon_1_version = var.custom_addon_1_version
  custom_addon_2         = var.custom_addon_2
  custom_addon_2_version = var.custom_addon_2_version
  custom_addon_3         = var.custom_addon_3
  custom_addon_3_version = var.custom_addon_3_version
  custom_addon_4         = var.custom_addon_4
  custom_addon_4_version = var.custom_addon_4_version
  custom_addon_5         = var.custom_addon_5
  custom_addon_5_version = var.custom_addon_5_version
  depends_on           = [ module.addons ]
}

module cluster {
  source                 = "./modules/aks"
  cluster_name           = var.cluster_name
  project                = var.project
  blueprint_name         = var.blueprint_name
  blueprint_version      = var.blueprint_version
  cloud_credentials_name = var.cloud_credentials_name
  cluster_resource_group = var.cluster_resource_group
  k8s_version            = var.k8s_version
  cluster_location       = var.cluster_location
  nodepool_name          = var.nodepool_name
  node_count             = var.node_count
  node_max_count         = var.node_max_count
  node_min_count         = var.node_min_count
  vm_size                = var.vm_size
  vm_username            = var.vm_username
  vm_sshkey              = var.vm_sshkey
  node_resource_group    = var.node_resource_group
  depends_on             = [ module.cloud_credentials, module.blueprint, module.cluster-overrides]
}
