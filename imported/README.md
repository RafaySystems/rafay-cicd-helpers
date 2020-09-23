## Requirements
- Linux OS/Mac OS/Winows
- Credentials with permissions to provision clusters in Rafay Platform
---
### Imported Cluster Provision

Sample declarative specs for imported cluster configurations are available [here](../imported/examples)

### Parameters that needs to be specified in the spec file

- kind - "Cluster"
- metadata.name - Name of the cluster that will be created in Rafay Platform
- metadata.project - Name of the project in Rafay platform where cluster needs to be created
- spec.type - "imported"
- spec.location - Location of the cluster where it is running
- spec.blueprint - Name of the blueprint with which cluster needs to be created

### Download Rafay CLI

``` wget -q https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2```

### Imported cluster creation

To apply the bootstrap file onto the cluster

```./rctl create cluster -f imported/examples/imported_cluster.yaml > cluster_bootstrap.yaml```


### Jenkins Pipeline Groovy script

An example jenkins pipeline groovy script can be found [here](../imported/Jenkins)