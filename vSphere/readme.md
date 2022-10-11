## Requirements
- Linux OS
- Ensure you have JQ (CLI based JSON Processor) installed. 
- You have configured a cloud credential in the Controller so that it can securely provision required infrastructure using vCenter.
- Ensure you have downloaded and configured the RCTL CLI with credentials with permissions to provision and manage clusters

---

## Provision Cluster

Ensure you have configured details correctly in the cluster specification YAML file. 

```./rctl apply -f examples/basic-cluster.yaml```

---

## Other Lifecycle Operations

Click [here](https://docs.rafay.co/clusters/vmware/cli/) for details on additional lifecycle operations such as 

- Scaling Up, Down
- Upgrade
- Deprovision

---

## Automation

Customers using external automation platforms (e.g. Jenkins, GitHub Actions, GitLab etc) can embed the RCTL CLI for complete lifecycle management of Upstream Kubernetes on vSphere environments. 

They can wrap the RCTL CLI with additional logic for progress and status checks. An illustrative example script is provided [here](https://github.com/RafaySystems/rafay-cicd-helpers/blob/master/vSphere/scripts/clusterstatus.sh). 

---