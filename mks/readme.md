
## Requirements
- A [supported OS](https://docs.rafay.co/cli/overview/) compatible with RCTL CLI
- Ensure you have JQ (CLI based JSON Processor) installed 
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

Customers using external automation platforms (e.g. Jenkins, GitHub Actions, GitLab etc) can embed the RCTL CLI for complete lifecycle management of Upstream Kubernetes on Bare Metal and VM-based environments. 

---

## Examples
A brief description of what each example cluster specification is designed for. 

### Basic Cluster
**File Name: "[mks-cluster-basic.yaml](mks-cluster-basic.yaml)"** 

A single node, converged (control plane and node) cluster specification identifying the following:

- A specific Kubernetes version
- Ubuntu 20.04 LTS OS
- Calico CNI
- IPv6 addresses


### Dedicated Master 
**File Name: "mks-dedicated-master.yaml"** 

A multi-node, cluster with a dedicated master node with the following:

- A specific Kubernetes version
- Ubuntu 20.04 LTS OS
- Flannel CNI
- IPv6 addresses
- Dedicated Master (Control Plane) Node
- (Worker) Node


### Multi Node Cluster 
**File Name: "mks-ha-cluster.yaml"** 

A multi-node, highly available (multi-master) cluster with the following:

- A specific Kubernetes version
- Ubuntu 20.04 LTS OS
- Calico CNI
- IPv6 addresses
- Three Dedicated Master (Control Plane) Nodes
- (Worker) Nodes

---