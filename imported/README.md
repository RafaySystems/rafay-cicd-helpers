## Requirements
- Linux OS
- Ensure you have [JQ (CLI based JSON Processor)](https://stedolan.github.io/jq/) installed. The script will automatically download and install if it is not detected.
- Ensure you have [cURL](https://curl.haxx.se/) installed.
- Ensure you have [PyYaml](https://pypi.org/project/PyYAML/) installed
- You have configured a cloud credential in the Rafay Controller so that it can securely provision required infrastructure.
- Credentials with permissions to provision clusters in Rafay Platform
---
### Imported Cluster Provision

Sample declarative specs for imported cluster configurations are available [here](../imported/examples)

### Parameters that needs to be specified in the spec file

- name - Name of the cluster that will be created in Rafay Platform
- kind - Type of the cluster that needs to be provisioned. For EKS cluster, kind needs to be "imported"
- namespace - Location of the cluster where it is running
- blueprint - Name of the blueprint with which cluster needs to be created
- project - Name of the project in Rafay platform where cluster needs to be created

### Imported cluster creation

To apply the bootstrap file onto the cluster

```scripts/rafay_imported_cluster.sh -u jonh.doe@example.com -p P@ssword -f examples/imported_cluster.yaml -a```

To apply the bootstrap file offline onto the cluster

```scripts/rafay_imported_cluster.sh -u jonh.doe@example.com -p P@ssword -f examples/imported_cluster.yaml```

### Jenkins Pipeline Groovy script

An example jenkins pipeline groovy script can be found [here](../imported/Jenkins)