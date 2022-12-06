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

module "blueprint" {
  source                 = "./modules/blueprints"
  project                = var.project
  blueprint_name         = var.blueprint_name
  blueprint_version      = var.blueprint_version
  base_blueprint         = var.base_blueprint
  base_blueprint_version = var.base_blueprint_version
  infra_addons           = var.infra_addons
  depends_on           = [ module.addons ]
}

module cluster {
  source                 = "./modules/aks"
  cluster_name           = var.cluster_name
  cluster_tags           = var.cluster_tags
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
  node_resource_group    = var.node_resource_group
  node_tags              = var.node_tags
  node_labels            = var.node_labels
  depends_on             = [ module.cloud_credentials, module.blueprint]
}
