variable "project_name" {
  default = "defaultproject"
}
variable "rafay_cloud_credential_name" {
   default = "eks-demo"
}
variable "rafay_cloud_credential_type" {
   default = "cluster-provisioning"
}
variable "iam_role_arn_value" {
   default = "arn:aws:iam::role"
}
variable "rafay_aws_cloud_credential_type" {
   default = "ROLE"
}
variable "access_key" {
   default = ""
}
variable "secret_key" {
   default = ""
}
variable rafay_aws_account_id {
	default = "ABCDEFG"
}

variable aws_iam_role_name {
   default = "rafay-eks-iam-role"
}

variable aws_iam_policy_name {
   default = "rafay-eks-iam-policy"
}
