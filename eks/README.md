## Requirements
- Linux OS
- Ensure you have [JQ (CLI based JSON Processor)](https://stedolan.github.io/jq/) installed. The script will automatically download and install if it is not detected.
- Ensure you have [cURL](https://curl.haxx.se/) installed.
- Ensure you have [PyYaml](https://pypi.org/project/PyYAML/) installed
- You have configured a cloud credential in the Rafay Controller so that it can securely provision required infrastructure.
- Credentials with permissions to provision clusters in Rafay Platform

---
### EKS Cluster Provision

Sample declarative specs for a variety of cluster configurations are available [here](../eks/examples)

### Parameters that needs to be specified in the spec file

- kind - Type of the cluster that needs to be provisioned. For EKS cluster, kind needs to be "AmazonEKS"
- general
    - name -  Name of the cluster that needs to be created on Rafay Platform
    - region - AWS region where the cluster will be launched
    - k8sVersion - Version of Kubernetes that will be used to launch EKS cluster
    - credentials - Name of the Cloud Provider credential that is created on Rafay Platform
    - blueprint - Name of the blueprint with which cluster needs to be created
    - project - Name of the project in Rafay platform where cluster needs to be created
- controlPlane
    - availabilityZones - Optional. Need to specify if you want the cluster be created in any specific AZ's
- networking
    - useExistingVpc - Specify whether cluster needs to be created in New VPC or existing VPC
    - vpc
        - nat
            - gateway - Specify how NAT gateway needs to be configured (HighlyAvailable, Disable, Single (default))
        - cidr - Specify the CIDR that you want to use.
        - subnets
            - private - Optional. Specify the private subnets that you want to use for the worker nodes for each Availability Zone
            - public -  Optional. Specify the public subnets that you want to use for the worker nodes for each Availability Zone
- nodeGroups
    - name - Name of the nodegroup that needs to be created
    - managed - Specify whether nodegroup will be a managed nodegroup or not
    - availabilityZones - Optional. Need to specify if you want the worker nodes to be created in any specific AZ's
    - privateNetworking - Specify whether nodegroup needs to be created in private subnets or not
    - instanceType - Instance type that will be used for the worker nodes
    - desiredCapacity - No of worker nodes that you want to run
    - minSize - Minimum no of worker nodes that you want to run
    - maxSize - Maximum no of worker nodes that you want to run
    - volumeSize - Size of the volume with which worker node needs to be launched
    - volumeType - Type of the volume with which worker node needs to be launched
    - ami - Optional. AMI ID which will be used to launch the worker nodes
    - amiFamily - Optional. Ami Family which will be used to launch the worker nodes
    - ssh
        - publicKeyName - Specify the key name to enable SSH access to worker nodes
    - securityGroups - Securty group ID's which needs to be attached to worker nodes
- iam
    - withAddonPolicies
        - albIngress - Specify whether ALB Ingress IAM role needs to be enabled or not
        - autoScalegroup - Specify whether autoScalegroup IAM role needs to be enabled or not
        - route53 - Specify whether route53 IAM role needs to be enabled or not
        - appmesh - Specify whether appmesh IAM role needs to be enabled or not
        - ecr - Specify whether ecr IAM role needs to be enabled or not
---
### EKS Cluster creation in new VPC

```scripts/rafay_eks_provision.sh -u jonh.doe@example.com -p P@ssword -f examples/eks-new-vpc.yaml```

### EKS Cluster creation in existing VPC with Custom AMI

```scripts/rafay_eks_provision.sh -u jonh.doe@example.com -p P@ssword -f examples/eks-existing-vpc-custom-ami.yaml```

### Jenkins Pipeline Groovy script

An example jenkins pipeline groovy script can be found [here](../eks/Jenkins)