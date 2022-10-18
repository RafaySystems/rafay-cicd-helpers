resource "rafay_blueprint" "blueprint" {
  metadata {
    name    = var.blueprint_name
    project = var.project
  }
  spec {
    version = var.blueprint_version
    base {
      name    = var.base_blueprint
      version = var.base_blueprint_version
    }
    custom_addons {
      name = var.custom_addon_1
      version = var.custom_addon_1_version
    }
    custom_addons {
      name = var.custom_addon_2
      version = var.custom_addon_2_version
    }
    custom_addons {
      depends_on = [var.custom_addon_2]
      name = var.custom_addon_3
      version = var.custom_addon_3_version
    }
    custom_addons {
      name = var.custom_addon_4
      version = var.custom_addon_4_version
    }
    custom_addons {
      name = var.custom_addon_5
      version = var.custom_addon_5_version
    }
    default_addons {
      enable_ingress    = false
      enable_monitoring = true
    }
    drift {
      action  = "Deny"
      enabled = true
    }
    sharing {
      enabled = false
    }
    opa_policy {
      opa_policy {
	      enabled = true
	      name = "policy-privileged"
	      version = "version-1633143424"
      }
      profile {
	      name = "default"
        version = "version-1664597317"
      }
    }
    namespace_config {
      enable_sync = true
    }
    network_policy {
      enabled = true
      profile {
        name = "default"
      }
    }
  }
}