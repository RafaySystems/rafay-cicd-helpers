## Requirements
- Linux OS
- Ensure you have JQ (CLI based JSON Processor) installed. 
- Cloud Credentials for GCP configured 
- Download and configure the RCTL CLI with credentials with permissions to provision and manage clusters

---

## Provision Cluster

Ensure you have configured details correctly in the cluster specification YAML file. Follow the Config Schema documentation. 

```./rctl apply -f examples/cluster.yaml```

---

## Other Lifecycle Operations

Click [here](https://docs.rafay.co/clusters/gke/cli/) for details on additional lifecycle operations such as 

- Scale Node Pool (Up or Down)
- Add Node Pool (Up or Down)
- Upgrade Kubernetes 
- Deprovision Cluster 

---

## Automation

Customers using external automation platforms (e.g. Jenkins, GitHub Actions, GitLab etc) can embed the RCTL CLI for complete lifecycle management of GKE clusters. 

---