## Requirements

This terraform example uses AWS provider. Hence it assumes your AWS configuration is configured on the system where you 
are running this terraform.

Also following RCTL environment variables needs to be set.

```
    RCTL_REST_ENDPOINT="console.rafay.dev"
    RCTL_OPS_ENDPOINT="console.rafay.dev"
    RCTL_API_KEY="xxxxxxxx"
    RCTL_API_SECRET="yyyyyyyyyyyyyyyyyyyy"
    RCTL_PROJECT="defaultproject"
```

This will create the following resources:

- New Project on Rafay
- AWS IAM Policy to provision EKS Cluster
- AWS IAM Role delegated to Rafay to provision EKS Cluster
- New Cloud Credential on Rafay with above IAM Role
- An EKS Cluster using the above Cloud Credential in the Project created above

## Configuration

Customize modules/rafay_cluster/eks-cluster.yaml with appropriate values.

Copy terraform-template.tfvars to terraform.tfvars
```
    cp terraform-template.tfvars terraform.tfvars
```

Edit terraform.tfvars to modify the following variables:
```
    project_name - Name of the Rafay project that will be created
    rafay_cloud_credential_name - Name of the Rafay Cloud Credential that will be created
    rafay_aws_account_id - Rafay AWS Account id that you will be delegating to 
    cluster_name - Name of the EKS Cluster name that will be created
    aws_iam_role_name - Name of the AWS IAM role that will be created
    aws_iam_policy_name - Name of the AWS IAM policy that will be created
```

## BUILD & RUN

  Execute below command to init with terraform
```
  terraform init
```

  For validating your configuration run below command
```
  terraform validate
```

  If validate is success, that means all the configuration is valid, then we can apply with terraform
```
  terraform apply -var-file=terraform.tfvars
```
  or
```
  terraform apply -var-file=terraform.tfvars -auto-approve
```