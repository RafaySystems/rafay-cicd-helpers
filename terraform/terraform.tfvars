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
k8s_version            =  "1.23.12"
nodepool_name          =  "pool1"
node_count             =  "2"
node_max_count         =  "3"
node_min_count         =  "1"
vm_size                =  "Standard_DS2_v2"
cluster_tags           = {
    "created-by" = "user"
    "to-test"    = "terraform"
}
node_tags = {
    "env" = "prod"

}
node_labels = {
    "type" = "aks"
}

#Blueprint/Addons specific varaibles
blueprint_name         = "custom-blueprint"
blueprint_version      = "v0"
base_blueprint         = "default-aks"
base_blueprint_version = "1.20.0"
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