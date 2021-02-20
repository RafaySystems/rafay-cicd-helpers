## Requirements
- Linux OS
- Ensure you have [JQ (CLI based JSON Processor)](https://stedolan.github.io/jq/) installed. The script will automatically download and install if it is not detected.
- Ensure you have [cURL](https://curl.haxx.se/) installed.
- Ensure you have [PyYaml](https://pypi.org/project/PyYAML/) installed
- You have configured a cloud credential in the Rafay Controller so that it can securely provision required infrastructure.
- Ensure you have downloaded Rafay CLI (RCTL)
- Credentials with permissions to provision clusters in Rafay Platform

---
### EKS Cluster Provision

Sample declarative specs for a variety of cluster configurations are available [here](../eks/examples)


---
### EKS Cluster creation in new VPC

```./rctl create cluster eks -f examples/eks-cluster.yaml```

### EKS Cluster creation in existing VPC with managed nodegroups

```./rctl create cluster eks -f examples/eks-cluster-managed-custom-vpc.yaml```

### Adding Nodegroup to an existing cluster
```./rctl create node-group -f eks-add-nodegroup.yaml```

### Jenkins Pipeline Groovy script

An example jenkins pipeline groovy script can be found [here](../eks/Jenkins)