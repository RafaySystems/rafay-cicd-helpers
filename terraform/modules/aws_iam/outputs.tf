output "external_id" {
  description = "External ID used to create IAM role"
  value       = random_uuid.test.result 
}

output "iam_role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.eks_access_role.arn 
}
