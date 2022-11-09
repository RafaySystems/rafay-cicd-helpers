## Requirements
- Linux OS
- Ensure you have JQ (CLI based JSON Processor) installed. 
- SSH access and credentials to your bare metal or VM based instances 
- Download and configure the RCTL CLI with credentials with permissions to provision and manage clusters

---

## Provision Cluster

Ensure you have configured details correctly in the cluster specification YAML file. Follow the Config Schema documentation. 

```./rctl apply -f examples/cluster.yaml```

---

## Other Lifecycle Operations

Click [here](https://docs.rafay.co/clusters/upstream/cli/) for details on additional lifecycle operations such as 

- Scaling Up, Down (Add/Remove Nodes)
- Upgrade Kubernetes 
- Deprovision Cluster 

---

## Automation

Customers using external automation platforms (e.g. Jenkins, GitHub Actions, GitLab etc) can embed the RCTL CLI for complete lifecycle management of Upstream Kubernetes on vSphere environments. 

---