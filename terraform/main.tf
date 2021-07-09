module "rafay_project" {
  source = "./modules/rafay_project"
  project_name    = var.project_name

}

module "rafay_cloud_credentials" {
  source = "./modules/rafay_cloud_credentials"
  providers = {
	aws = aws
  }
  depends_on = [module.rafay_project]

  project_name      = var.project_name
  rafay_cloud_credential_name         = var.rafay_cloud_credential_name
  aws_iam_role_name = var.aws_iam_role_name
  aws_iam_policy_name = var.aws_iam_policy_name
  rafay_aws_account_id = var.rafay_aws_account_id
}

module "rafay_cluster" {
  source = "./modules/rafay_cluster"

  depends_on = [module.rafay_cloud_credentials]
  cluster_name    = var.cluster_name
  project_name    = var.project_name
  rafay_cloud_credential_name       = var.rafay_cloud_credential_name
}
