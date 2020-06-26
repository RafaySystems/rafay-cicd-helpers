## Requirements
- Linux OS
- Ensure you have [JQ (CLI based JSON Processor)](https://stedolan.github.io/jq/) installed. The script will automatically download and install if it is not detected.
- Ensure you have [cURL](https://curl.haxx.se/) installed.
- Ensure you have [PyYaml](https://pypi.org/project/PyYAML/) installed
- You have configured a cloud credential in the Rafay Controller so that it can securely provision required infrastructure.
- Credentials with permissions to provision clusters in Rafay Platform
---
### MKS Cluster Provision

Sample declarative specs for a variety of cluster configurations are available [here](../mks/examples)

### Parameters that needs to be specified in the spec file

- cluster_name - Name of the cluster that will be created in Rafay Platform
- cluster_type - For Rafay MKS on AWS EC2, cluster_type needs to be "aws-ec2"
- cluster_provider_region - AWS region where the cluster will be launched
- cluster_provider_credentials - Name of the Cloud Provider credential that is created on Rafay Platform
- cluster_instance_type - EC2 instance type which will be used to provision the cluster
- cluster_multi_master - Whether HA cluster needs to be created or not
- cluster_gpu_provision - Whether GPU needs to be provisioned or not on the cluster
- cluster_blueprint - Name of the blueprint with which cluster needs to be created
- project - Name of the project in Rafay platform where cluster needs to be created

### Rafay MKS Non-HA cluster creation on AWS EC2

```scripts/rafay_mks_cluster.sh -u jonh.doe@example.com -p P@ssword -f examples/mks-non-ha.yaml```

### Rafay MKS HA cluster creation on AWS EC2

```scripts/rafay_mks_cluster.sh -u jonh.doe@example.com -p P@ssword -f examples/mks-ha.yaml```

### Rafay MKS HA cluster creation with GPU on AWS EC2

```scripts/rafay_mks_cluster.sh -u jonh.doe@example.com -p P@ssword -f examples/mks-ha-with-gpu.yaml```