## Introduction


In addition to using the Rafay Console to
- configure and provision clusters
- configure addons
- configure blueprints

you can also use REST APIs to programmatically interact with the Rafay Controller.

For users that have a need for declarative cluster specs, Rafay also provides the means to do this via turnkey scripts.

You can create and manage "cluster specs" to provision Rafay MKS and Amazon EKS Clusters on demand. This is well suited for scenarios where the cluster lifecyle (creation etc) needs to be embedded into a larger workflow where reproducible environments are required. For example:

- Jenkins or a CI system that needs to provision a cluster as part of a larger workflow
- Reproducible Infrastructure
- Ephemeral clusters for QA/Testing


---
## Addons

All cluster blueprints are comprised of one or more software add ons. When add ons are assembled together, they consititute a cluster blueprint.

Good candidates for "add ons" in a cluster blueprint are things that are meant to be services or operate silently in the background.

- Service Mesh (Istio, Linkerd etc)
- Ingress Controllers (Nginx etc)
- Security Products (StackRox, Twistlock, Sysdig etc)
- Cluster Monitoring
- Log Collection
- Backup and Restore

### Addon creation using a declrataive spec

[ Instructions on how to create an addon using a declartive spec can be found here ](addon/README.md)


---
## Cluster Blueprints

All clusters (both imported and provisioned) managed by Rafay have a "Default Blueprint" applied to the clusters by default. The default blueprint comprises "essential" add ons that are critical for core Rafay provided capabilities.
Users can assemble and configure a list of "software add ons" as part of a custom blueprint and apply it to their fleet of clusters.

### Cluter Blueprint creation using a declrataive spec

[ Instructions on how to create a cluster blueprint using a declartive spec can be found here ](blueprint/README.md)

---
## Clusters

Rafay supports two types of Kubernetes clusters that can be used for multi cluster workload deployments.

---

### 1. Provisioned Clusters

These are Kubernetes clusters that are provisioned and managed by Rafay on various types of infrastructure

- Upstream k8s On Bare Metal
- Upstream k8s On Virtual Machines (on vSphere, AWS, GCP, Azure etc)
- Managed Kubernetes Providers (EKS, etc)

Rafay can perform full lifecycle management of provisioned clusters.

---

### 2. Imported Clusters

Kubernetes clusters that have already been provisioned can be imported into Rafay via the Operations Console. Once imported, Rafay will provide deep visibility and insight into all aspects of the Kubernetes cluster. Rafay can also deploy customer applications to an "imported cluster".

The lifecycle management (add/remove worker nodes, decommission etc) of an "imported" Kubernetes cluster is the responsibility of the customer.

!!! IMPORTANT
    Kubernetes v1.14.1 or higher is the minimum supported version.

---

### Rafay MKS cluster creation on AWS using EC2 instances

[ Instructions on how to create a Rafay MKS cluster using a declartive spec can be found here ](mks/README.md)


---

### EKS cluster creation

[ Instructions on how to create an EKS cluster using a declartive spec can be found here ](eks/README.md)


### Imported cluster creation

[ Instructions on how to create an imported cluster using a declartive spec can be found here ](imported/README.md)

