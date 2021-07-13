## Requirements

Configure following RCTL environment variables.

```
    RCTL_REST_ENDPOINT="console.rafay.dev"
    RCTL_OPS_ENDPOINT="console.rafay.dev"
    RCTL_API_KEY="xxxxxxxx"
    RCTL_API_SECRET="yyyyyyyyyyyyyyyyyyyy"
    RCTL_PROJECT="defaultproject"
```

## Overview

This will create the following resources:

- Associate the given Rafay project to a given User Group with mentioned RBAC roles

## Configuration

Copy terraform-template.tfvars to terraform.tfvars
```
    cp terraform-template.tfvars terraform.tfvars
```

Edit terraform.tfvars to modify the following variables:
```
    project_name - Name of the project that you want to enable RBAC
    group_name - Name of the User group that you want to associate with above project_name
    roles - List of RBAC roles that you want to enable for the above user group. See below for the supported roles
```

  Roles :
```       ADMIN,
	  PROJECT_ADMIN,
	  PROJECT_READ_ONLY,
	  INFRA_ADMIN,
	  INFRA_READ_ONLY,
	  NAMESPACE_READ_ONLY,
	  NAMESPACE_ADMIN
```           
   To specify a Single Role:
```
  roles = "PROJECT_READ_ONLY"
```
  
  To specify Multiple Roles:
```
    roles = "PROJECT_READ_ONLY,PROJECT_ADMIN"
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
  terraform apply"
```
  or
```
  terraform apply -auto-approve
```