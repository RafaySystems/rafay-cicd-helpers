#Poject name variable
project               = "terraform"

#Cloud Credentials specific varaibles
cloud_credentials_name  = "cloud-credentials"
#Specity Service prinicipal info below for AKS.
subscription_id         = ""
tenant_id               = ""
client_id               = ""
client_secret           = ""
# Specify Role ARN & externalid infor below for EKS.
rolearn                 = "arn:aws:iam::<AWS_ACCOUNT_NUMBER>:role/<AWS_ROLE>"
externalid              = "d547-098f-bdd4-a30b-c4bd"

#Cluster specific varaibles
cluster_name           =  "<CLUSTER_NAME>"
cluster_resource_group =  "<AKS_RESOURCE_GROUP>"
cluster_location       =  "<CLUSTER_LOCATION/REGION>"
k8s_version            =  "<K8S_VERSION>"
nodepool_name          =  "pool1"
node_count             =  "2"
node_max_count         =  "3"
node_min_count         =  "1"

#Cluster Sharing
sharing = true
# VM Size for AKS
vm_size                =  "Standard_DS2_v2"
ng_name                = "pool1"
# Instance Type for EKS
instance_type          = "t3.xlarge"
cluster_tags           = {
    "created-by" = "user"
    "to-test"    = "terraform"
}
node_tags = {
    "env" = "prod"

}
node_labels = {
    "type" = "eks"
}

#Blueprint/Addons specific varaibles
blueprint_name         = "custom-blueprint"
blueprint_version      = "v0"
base_blueprint         = "default"
base_blueprint_version = "1.22.0"
namespaces              = ["ingress-nginx", "istio-system", "datadog", "cert-manager"]
infra_addons = {
    "addon1" = {
         name          = "ingress-nginx"
         namespace     = "ingress-nginx"
         addon_version = "v1.3.1"
         chart_name    = "ingress-nginx"
         chart_version = "4.2.5"
         repository    = "nginx-controller"
         file_path     = null
    }
    "addon2" = {
         name          = "istio-base"
         namespace     = "istio-system"
         addon_version = "v1.15.0"
         chart_name    = "base"
         chart_version = "1.15.0"
         repository    = "istio"
         file_path     = null

    }
     "addon3" = {
         name          = "istiod"
         namespace     = "istio-system"
         addon_version = "v1.15.0"
         chart_name    = "istiod"
         chart_version = "1.15.0"
         repository    = "istio"
         file_path     = null
    }
    "addon4" = {
         name          = "cert-manager"
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
            #For AKS
            #service.beta.kubernetes.io/azure-load-balancer-internal: "false"
            #FOR EKS
            service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      EOT
    }
    "istiod" = {
      override_addon_name = "istiod"
      override_values = <<-EOT
      pilot:
        autoscaleMin: 2
        replicaCount: 2
      EOT
    }
}

application_projects = {
    project1 = {
        name          = "<PROJECT_NAME1>"
        description   = "team1"
        # Define resource quotas(small/medium/large). Defined under modules/multi-tenancy/variables.tf
        size          = "small"
        groups         = {
            group1 = {
                name  = "<GROUP_NAME1_WK_ADMIN>"
                roles = ["WORKSPACE_ADMIN"]
            }
            group2 = {
                name = "GROUP_NAME1_WK_READ"
                roles = ["WORKSPACE_READ_ONLY"]
            }
        }
    }
    project2 = {
        name          = "PROJECT_NAME2"
        description   = "team2"
        size          = "large"
        groups         = {
            group1 = {
                name  = "GROUP_NAME2_WK_ADMIN"
                roles = ["WORKSPACE_ADMIN"]
            }
            group2 = {
                name = "GROUP_NAME2_WK_READ"
                roles = ["WORKSPACE_READ_ONLY"]
            }
        }
    }
}