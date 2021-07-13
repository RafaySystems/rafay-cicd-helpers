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

- New User Group in Rafay

## Configuration

Copy terraform-template.tfvars to terraform.tfvars
```
    cp terraform-template.tfvars terraform.tfvars
```

Edit terraform.tfvars to modify the following variables:
```
    group_name - Name of the User group that will be created in Rafay
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
  terraform apply
```
  or
```
  terraform apply -auto-approve
```