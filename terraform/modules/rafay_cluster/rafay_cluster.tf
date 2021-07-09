resource "null_resource" "cluster" {
    triggers = {
      cluster_name     = var.cluster_name
      project_name     = var.project_name
    }
  provisioner "local-exec" {
    interpreter = ["/bin/bash","-c"]
    command = "${path.module}/rafay_eks_provision.sh ${path.module}/eks-cluster.yaml"
    environment = {
      CLUSTER_NAME      = var.cluster_name 
      PROJECT_NAME      = var.project_name 
      CREDENTIALS_NAME  = var.rafay_cloud_credential_name
    } 
  }

  provisioner "local-exec" {
    when    = destroy
    interpreter = ["/bin/bash","-c"]
    command = "${path.module}/rafay_eks_cleanup.sh ${self.triggers.cluster_name} ${self.triggers.project_name}"
  }
}

