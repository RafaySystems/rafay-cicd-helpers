variable "project" {
  type = string
}

variable "public_repositories" {
  type = map(object({
    endpoint  = string
    type      = string
  }))
}

variable "infra_addons" {
  type = map(object({
    namespace     = string
    addon_version = string
    chart_name    = string
    chart_version = string
    repository    = string
    file_path     = string
  }))
}

variable "rafay_config_file" {
  type    = string
  default = "./artifacts/credentials/config.json"
}

variable "blueprint_name" {
  type = string
}

variable "blueprint_version" {
  type = string
}

variable "base_blueprint" {
  type = string
}

variable "base_blueprint_version" {
  type = string
}

variable "custom_addon_1" {
  type = string
}

variable "custom_addon_1_version" {
  type = string
}

variable "custom_addon_2" {
  type = string
}

variable "custom_addon_2_version" {
  type = string
}

variable "custom_addon_3" {
  type = string
}

variable "custom_addon_3_version" {
  type = string
}

variable "custom_addon_4" {
  type = string
}

variable "custom_addon_4_version" {
  type = string
}

variable "custom_addon_5" {
  type = string
}

variable "custom_addon_5_version" {
  type = string
}

variable "cluster_name" {
    type = string
}

variable "namespaces" {
    type = list(string)
}

variable "cloud_credentials_name" {
  type = string
}

variable "cluster_resource_group" {
  type = string
}

variable "cluster_location" {
  type = string
}

variable "k8s_version" {
  type = string
}

variable "nodepool_name" {
  type = string
}

variable "node_count" {
  type = string
}

variable "node_max_count" {
  type = string
}

variable "node_min_count" {
  type = string
}

variable "vm_size" {
  type = string
}


variable "client_id" {
  type = string
}

variable "client_secret" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "vm_username" {
  type = string
}

variable "vm_sshkey" {
  type = string
}

variable "node_resource_group" {
  type = string
}

variable "overrides_config" {
  type = map(object({
    override_addon_name   = string
    override_values       = string
  }))
}
