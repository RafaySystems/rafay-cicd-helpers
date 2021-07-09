resource "random_uuid" "test" {
}

module "iam" {
  source = "../aws_iam"

  account_id	= var.rafay_aws_account_id
  aws_iam_role_name = var.aws_iam_role_name
  aws_iam_policy_name = var.aws_iam_policy_name
}

resource "null_resource" "cluster" {
  triggers = {
    project_name  = var.project_name
    rafay_cloud_credential_name     = var.rafay_cloud_credential_name
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash","-c"]
    command = "${path.module}/rafay_credential.sh"
    environment = {
      PROJECT_NAME      = var.project_name
      CRED_NAME		= var.rafay_cloud_credential_name
      CRED_TYPE		= var.rafay_cloud_credential_type
      CRED_AWS_TYPE	= var.rafay_aws_cloud_credential_type
      ROLEARN_VALUE	= module.iam.iam_role_arn
      EXTERNAL_ID	= module.iam.external_id
    }
  }

  provisioner "local-exec" {
    when    = destroy
    interpreter = ["/bin/bash","-c"]
    command = "${path.module}/rafay_cred_cleanup.sh ${self.triggers.rafay_cloud_credential_name} ${self.triggers.project_name}"
    
  }
}
