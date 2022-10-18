#Poject name variable
project               = "terraform"

#Cloud Credentials specific varaibles
cloud_credentials_name  = "aks-cloud-credentials"
subscription_id         = "<SUBSCRIPTION_ID>"
tenant_id               = "<TENANT_ID>"
client_id               = "<CLIENT_ID>"
client_secret           = "<CLIENT_SECRET>"

#Cluster specific varaibles
cluster_name           =  "aks-cluster"
cluster_resource_group =  "<RESOURCE_GROUP_NAME>"
node_resource_group    =  "<NODEPOOL_RESOURCE_GROUP_NAME>"
cluster_location       =  "centralindia"
k8s_version            =  "1.22.11"
nodepool_name          =  "pool1"
node_count             =  "2"
node_max_count         =  "3"
node_min_count         =  "1"
vm_size                =  "Standard_DS2_v2"
vm_username            =  "<USERNAME>"
vm_sshkey              =  "<SSH_PUBLIC_KEY>"

#Blueprint/Addons specific varaibles
blueprint_name         = "custom-blueprint"
blueprint_version      = "v2"
base_blueprint         = "default-aks"
base_blueprint_version = "1.18.0"
custom_addon_1         = "ingress-nginx"
custom_addon_1_version = "v1.3.1"
custom_addon_2         = "istio-base"
custom_addon_2_version = "v1.15.0"
custom_addon_3         = "istiod"
custom_addon_3_version = "v1.15.0"
custom_addon_4         = "datadog"
custom_addon_4_version = "v7"
custom_addon_5         = "cert-manager"
custom_addon_5_version = "v1.9.1"
namespaces              = ["ingress-nginx", "istio-system", "datadog", "cert-manager"]
infra_addons = {
    "ingress-nginx" = {
         namespace     = "ingress-nginx"
         addon_version = "v1.3.1"
         chart_name    = "ingress-nginx"
         chart_version = "4.2.5"
         repository    = "nginx-controller"
         file_path     = null
    }
    "istio-base" = {
         namespace     = "istio-system"
         addon_version = "v1.15.0"
         chart_name    = "base"
         chart_version = "1.15.0"
         repository    = "istio"
         file_path     = null

    }
     "istiod" = {
         namespace     = "istio-system"
         addon_version = "v1.15.0"
         chart_name    = "istiod"
         chart_version = "1.15.0"
         repository    = "istio"
         file_path     = null
    }
    "datadog" = {
         namespace     = "datadog"
         addon_version = "v7"
         chart_name    = "datadog"
         chart_version = "3.1.1"
         repository    = "datadog"
         file_path     = "file://artifacts/datadog/custom_values.yaml"
    }
    "cert-manager" = {
         namespace     = "cert-manager"
         addon_version = "v1.9.1"
         chart_name    = "cert-manager"
         chart_version = "v1.9.1"
         repository    = "cert-manager"
         file_path     = "file://artifacts/cert-manager/custom_values.yaml"
    }
}

#Repository specific variables
public_repositories = {
    "nginx-controller" = {
        type = "Helm"
        endpoint = "https://kubernetes.github.io/ingress-nginx"
    }
    "istio" = {
        type = "Helm"
        endpoint = "https://istio-release.storage.googleapis.com/charts"
    }
    "datadog" = {
        type = "Helm"
        endpoint = "https://helm.datadoghq.com"
    }
    "cert-manager" = {
        type = "Helm"
        endpoint = "https://charts.jetstack.io"
    }
}

#Override config
overrides_config = {
    "ingress-nginx" = {
      override_addon_name = "ingress-nginx"
      override_values = <<-EOT
      controller:
        service:
          annotations:
            service.beta.kubernetes.io/azure-load-balancer-internal: "true"
            service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "<SUBNET_NAME>"
      EOT
    }
}
