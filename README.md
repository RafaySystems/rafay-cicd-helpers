---
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

[ Instructions on how to create an addon using a declartive spec can be found here ](addons/README.md)


---
## Cluster Blueprints

All clusters (both imported and provisioned) managed by Rafay have a "Default Blueprint" applied to the clusters by default. The default blueprint comprises "essential" add ons that are critical for core Rafay provided capabilities.
Users can assemble and configure a list of "software add ons" as part of a custom blueprint and apply it to their fleet of clusters.

### Cluter Blueprint creation using a declrataive spec

[ Instructions on how to create a cluster blueprint using a declartive spec can be found here ](blueprints/README.md)

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


```yaml
---
# Type of k8s Distribution: AmazonEKS
kind: AmazonEKS
general:
  # Name of Cluster in Rafay Controller
  name: demo-eks-cluster
  # AWS Region where cluster needs to be provisioned
  region: us-west-2
  # Supported Kubernetes Version for EKS
  k8sVersion: 1.15
  # Name of Rafay Cloud Credentials (can be based on IAM User or Role)
  credentials: eks_role_credentials
  # Name of blueprint to be used
  blueprint: default
  # Name of project where cluster has to be provisioned
  project: testing
controlPlane:
  # Specify the AZs where the EKS Master will be provisioned
  availabilityZones: []

networking:
  # If false, will create new VPCs and Subnets
  useExistingVpc: false
  vpc:
    # NAT Gateway: HighlyAvailable, Disable, Single (default)
    nat:
      gateway: "Single"
    cidr: "192.168.0.0/16"

    subnets:
    # Must provide 'private' and/or 'public' subnets by AZ as shown
    # Subnets will be created if nothing is specified
      private:
          us-east-1a:
             id: "subnet-abcd"
          us-east-1c:
             id: "subnet-defg"
      public:
          us-east-1a:
             id: "subnet-ghij"
          us-east-1c:
             id: "subnet-jklm"

# Worker Nodes Nodegroup details. Can have multiple nodegroups
nodeGroups:
    name: first-ng
    managed: false
    # AZ where the nodegroup's worker nodes will be provisioned
    availabilityZones: []

    privateNetworking: false

    # EC2 Instance Type
    instanceType: m5.xlarge
    # Number of Worker Nodes and ASG Details
    desiredCapacity: 1
    minSize: 1
    maxSize: 1

    # Storage for Worker Nodes
    volumeSize: 100
    volumeType: gp2
    # AMI Details
    ami:
    amiFamily:
    # SSH Key Details
    ssh:
      publicKeyName:
    securityGroups: []

# AWS IAM automation
iam:
  withAddonPolicies:
    albIngress: false
    autoScalegroup: true
    route53: false
    appmesh: false
    ecr: true
```

---

## Automation Scripts

Rafay has developed high level, easy to use "bash scripts" that you can use for both provisioning and deprovisioning. You can embed these scripts "as is" into an existing CI system such as Jenkins for build out automation. Alternatively, users can modify the provided code for the scripts to suit their requirements.

---
### Example Jenkins Pipeline

Have a look at an illustrative [example Jenkins pipeline](../../../integrations/ci/jenkins_eks.md) showcasing how you can automate provisioning of a Rafay MKS cluster on Amazon AWS.

---


### Requirements
- Linux OS
- Ensure you have [JQ (CLI based JSON Processor)](https://stedolan.github.io/jq/) installed. The script will automatically download and install if it is not detected.
- Ensure you [cURL](https://curl.haxx.se/) installed.
- You have configured a cloud credential in the Rafay Controller so that it can securely provision required infrastructure.

---

### Provision Cluster

Use this script to provision an Amazon EKS cluster on AWS. The script expects you to provide a declarative "cluster spec" as input along with credentials to access the Rafay Controller.

The script expects the following items as input

- Access credentials for Rafay Controller
- Cluster Spec YAML file

```sh
#!/bin/bash

SCRIPT='rafay_eks_provision.sh'

function HELP {
  echo -e "\nUsage: $SCRIPT [-u <Username>] [-p <Password>] [-f <cluster meta file>] "
  echo -e "\t-u  Username to login to the Rafay Console"
  echo -e "\t-p  Password to login to the Rafay Console"
  echo -e "\t-f  cluster meta file"
  echo
  echo -e "\nExample:  $SCRIPT -u test@example.com -p test123 -f cluster_meta.yaml"
  echo
  exit 1
}

NUMARGS=$#
if [ $NUMARGS -eq 0 ]; then
  HELP
fi

while getopts :u:p:f:h FLAG; do
  case $FLAG in
    u)
      USERNAME=$OPTARG
      ;;
    p)
      PASSWORD=$OPTARG
      ;;
    f)
      CLUSTER_META_FILE=$OPTARG
      ;;
    h)  #show help
      HELP
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -$OPTARG not recognized."
      HELP
      ;;
  esac
done

if [[ "$OSTYPE" == "linux-gnu"* ]];
then
    #Install jq if not installed
    JQ_PKG_OK=$(dpkg-query -W --showformat='${Status}\n' jq|grep "install ok installed")
    echo Checking for jq package: $JQ_PKG_OK
    if [ "" == "$JQ_PKG_OK" ]; then
        echo "jq package not installed. Installing jq..."
        sudo apt-get -y install jq
    fi

    #Install curl if not installed
    CURL_PKG_OK=$(dpkg-query -W --showformat='${Status}\n' curl|grep "install ok installed")
    echo Checking for curl package: $CURL_PKG_OK
    if [ "" == "$CURL_PKG_OK" ]; then
        echo "curl package not installed. Installing curl..."
        sudo apt-get -y install curl
    fi
elif [[ "$OSTYPE" == "darwin"* ]];
then
    if !(which jq > /dev/null 2>&1);
    then
        echo "jq installation not found, please install jq !! Exiting" && exit -1
    fi
    if !(which curl > /dev/null 2>&1);
    then
        echo "curl installation not found, please install curl !! Exiting" && exit -1
    fi
fi


if which python > /dev/null 2>&1;
then
   python=python
elif which python3 > /dev/null 2>&1;
then
   python=python3
else
   echo "python installation not found, please install python or python3 !! Exiting" && exit -1
fi

USERDATA='{"username":"'"${USERNAME}"'","password":"'"${PASSWORD}"'"}'
OPS_HOST="console.rafay.dev"

CLUSTER_TYPE=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.kind' | tr \" " " | tr -d "\n"|tr -d "[:space:]"`
CLUSTER_NAME=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.general.name' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_PROVIDER_REGION=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.general.region' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_PROVIDER_CREDENTIALS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.general.credentials' | tr \" " " | awk '{print $1}' | tr -d "\n"`
K8S_VERSION=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.general.k8sVersion' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_BLUEPRINT=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.general.blueprint' | tr \" " " | awk '{print $1}' | tr -d "\n"`
PROJECT=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.general.project' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CONTROL_PLANE_AZS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.controlPlane.availabilityZones'|tr "[" " "|tr "]" " "|tr -d "\n"|tr -d "[:space:]"|sed 's/"/\\"/g'`

cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | grep -w public > /dev/null 2>&1
if [ $? -ne 0 ];
then
    PUBLIC_SUBNETS=''
else
    PUBLIC_SUBNETS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.networking.vpc.subnets.public' | tr \" " " | awk '{print $1}' | tr -d "\n"`
    if [ $PUBLIC_SUBNETS == "null" ];
    then
        PUBLIC_SUBNETS=''
    else
        PUBLIC_SUBNETS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.networking.vpc.subnets.public[].id'| tr [:space:] ","|sed 's/.$//'`
    fi
fi

cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | grep -w private > /dev/null 2>&1
if [ $? -ne 0 ];
then
    PRIVATE_SUBNETS=''
else
    PRIVATE_SUBNETS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.networking.vpc.subnets.private' | tr \" " " | awk '{print $1}' | tr -d "\n"`
    if [ $PRIVATE_SUBNETS == "null" ];
    then
        PRIVATE_SUBNETS=''
    else
        PRIVATE_SUBNETS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.networking.vpc.subnets.private[].id'| tr [:space:] ","|sed 's/.$//'`
    fi
fi

USE_EXISTING_VPC=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.networking.useExistingVpc' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NAT_GATEWAY_MODE=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.networking.vpc.nat.gateway' | tr \" " " | awk '{print $1}' | tr -d "\n"`
VPC_CIDR=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.networking.vpc.cidr' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODES_DESIRED=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.desiredCapacity' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODES_MIN=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.minSize' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODES_MAX=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.maxSize' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODEGROUP_NAME=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.name' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODEGROUP_INSTANCE_TYPE=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.instanceType' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODEGROUP_MANAGED=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.managed' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODEGROUP_AVAILABILITY_ZONES=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.availabilityZones' |tr "[" " "|tr "]" " "|tr -d "\n"|tr -d "[:space:]"|sed 's/"/\\"/g'`
NODEGROUP_PRIVATE_NETWORKING=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.privateNetworking' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODEGROUP_SECURITY_GROUPS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.securityGroups' | tr "[" " "|tr "]" " "|tr -d "\n"|tr -d "[:space:]"`
NODE_VOLUME_SIZE=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.volumeSize' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODE_VOLUME_TYPE=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.volumeType' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODE_AMI_FAMILY=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.amiFamily' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODE_AMI=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.ami' | tr \" " " | awk '{print $1}' | tr -d "\n"`
NODE_SSH_KEY=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.nodeGroups.ssh.publicKeyName' | tr \" " " | awk '{print $1}' | tr -d "\n"`
IAM_ALB=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.iam.withAddonPolicies.albIngress' | tr \" " " | awk '{print $1}' | tr -d "\n"`
IAM_ASG=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.iam.withAddonPolicies.autoScalegroup' | tr \" " " | awk '{print $1}' | tr -d "\n"`
IAM_ROUTE53=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.iam.withAddonPolicies.route53' | tr \" " " | awk '{print $1}' | tr -d "\n"`
IAM_APPMESH=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.iam.withAddonPolicies.appmesh' | tr \" " " | awk '{print $1}' | tr -d "\n"`
IAM_ECR=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.iam.withAddonPolicies.ecr' | tr \" " " | awk '{print $1}' | tr -d "\n"`


if [ $CLUSTER_TYPE != "AmazonEKS" ];
then
    echo "Valid input for kind is "AmazonEKS" !! Exiting" && exit -1
fi

case $K8S_VERSION in
  ("1.14"|"1.15") ;;
  (*) echo "Valid input for general.k8sVersion is "1.14" or "1.15" !! Exiting" && exit -1;;
esac

case $USE_EXISTING_VPC in
  (true|false) ;;
  (*) echo "Valid input for networking.useExistingVpc is "true" or "false" !! Exiting" && exit -1;;
esac

case $NAT_GATEWAY_MODE in
  (Single|HighlyAvailable) ;;
  (*) echo "Valid input for networking.vpc.nat.gateway is "Single" or "HighlyAvailable" !! Exiting" && exit -1;;
esac

case $NODEGROUP_MANAGED in
  (true|false) ;;
  (*) echo "Valid input for nodeGroups.managed is "true" or "false" !! Exiting" && exit -1;;
esac

case $NODEGROUP_PRIVATE_NETWORKING in
  (true|false) ;;
  (*) echo "Valid input for nodeGroups.privateNetworking is "true" or "false" !! Exiting" && exit -1;;
esac

case $NODE_AMI_FAMILY in
  (AmazonLinux2|Ubuntu1804|null) ;;
  (*) echo "Valid input for nodeGroups.amiFamily is "AmazonLinux2" or "Ubuntu1804" !! Exiting" && exit -1;;
esac

case $NODE_VOLUME_TYPE in
  (gp2|sc1|st1) ;;
  (*) echo "Valid input for nodeGroups.volumeType is "gp2" or "sc1" or "st1" !! Exiting" && exit -1;;
esac

case $IAM_ALB in
  (true|false) ;;
  (*) echo "Valid input for iam.withAddonPolicies.albIngress is "true" or "false" !! Exiting" && exit -1;;
esac

case $IAM_ASG in
  (true|false) ;;
  (*) echo "Valid input for iam.withAddonPolicies.autoScalegroup is "true" or "false" !! Exiting" && exit -1;;
esac

case $IAM_ROUTE53 in
  (true|false) ;;
  (*) echo "Valid input for iam.withAddonPolicies.route53 is "true" or "false" !! Exiting" && exit -1;;
esac

case $IAM_APPMESH in
  (true|false) ;;
  (*) echo "Valid input for iam.withAddonPolicies.appmesh is "true" or "false" !! Exiting" && exit -1;;
esac

case $IAM_ECR in
  (true|false) ;;
  (*) echo "Valid input for iam.withAddonPolicies.ecr is "true" or "false" !! Exiting" && exit -1;;
esac

curl -k -vvvv -d ${USERDATA} -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8"  -X POST  https://${OPS_HOST}/auth/v1/login/ > /tmp/$$_curl 2>&1
csrf_token=`grep -inr "set-cookie: csrftoken" /tmp/$$_curl |  cut -d'=' -f2 | cut -d';' -f1`
rsid=`grep -inr "set-cookie: rsid" /tmp/$$_curl |  cut -d'=' -f2 | cut -d';' -f1`
rm /tmp/$$_curl


LookupProvider () {
  local cluster match="$1"
  shift
  for cluster; do [[ "$cluster" == "$match" ]] && return 0; done
  return 1
}

projects=`curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/auth/v1/projects/ | jq '.results[]|.name,.id' |cut -d'"' -f2`


PROJECTS_ARRAY=( $projects )
LookupProvider $PROJECT "${PROJECTS_ARRAY[@]}"
[ $? -ne 0 ] && echo -e " !! Could not find the project with the name $PROJECT !! Exiting  " && exit -1

for i in "${!PROJECTS_ARRAY[@]}";
do
    if [ ${PROJECTS_ARRAY[$i]} == "null" ];
    then
        echo "No Projects found !! Exiting" && exit -1
    elif [ ${PROJECTS_ARRAY[$i]} == $PROJECT ];
    then
        PROJECT_ID=${PROJECTS_ARRAY[$(( $i + 1))]}
        break
    fi
done

providers=`curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/providers/ | jq '.results[]|.name,.ID' |cut -d'"' -f2`


PROVIDERS_ARRAY=( $providers )
LookupProvider $CLUSTER_PROVIDER_CREDENTIALS "${PROVIDERS_ARRAY[@]}"
[ $? -ne 0 ] && echo -e " !! Could not find the provider with the name $CLUSTER_PROVIDER_CREDENTIALS !! Exiting  " && exit -1

for i in "${!PROVIDERS_ARRAY[@]}";
do
    if [ ${PROVIDERS_ARRAY[$i]} == "null" ];
    then
        echo "No Cloud Providers found !! Exiting" && exit -1
    elif [ ${PROVIDERS_ARRAY[$i]} == $CLUSTER_PROVIDER_CREDENTIALS ];
    then
        PROVIDER_ID=${PROVIDERS_ARRAY[$(( $i + 1))]}
        break
    fi
done

if [ $CLUSTER_TYPE == "AmazonEKS" ];
then
    CLUSTER_TYPE="aws-eks"
fi

if [ $VPC_CIDR == "null" ];
then
    VPC_CIDR="192.168.0.0/16"
fi

if [ $NAT_GATEWAY_MODE == "null" ];
then
    NAT_GATEWAY_MODE="Single"
fi

if [ $NODE_SSH_KEY == "null" ];
then
    NODE_SSH_KEY=''
fi

if [ $NODE_AMI_FAMILY == "null" ];
then
    NODE_AMI_FAMILY=''
fi

if [ $NODE_AMI == "null" ];
then
    NODE_AMI=''
fi

if [[ "$NODE_AMI_FAMILY" == ''  &&  "$NODE_AMI" == '' ]];
then
    NODE_AMI_FAMILY='AmazonLinux2'
fi

if grep -q "null" <<< "$PUBLIC_SUBNETS";
then
   PUBLIC_SUBNETS=''
else
   PUB_SUBNETS=$(echo "$PUBLIC_SUBNETS"  | sed 's/"/\\"/g')
   VPC_CIDR=''
fi

if grep -q "null" <<< "$PRIVATE_SUBNETS";
then
   PRIVATE_SUBNETS=''
else
   PRI_SUBNETS=$(echo "$PRIVATE_SUBNETS"  | sed 's/"/\\"/g')
   VPC_CIDR=''
fi

if grep -q "null" <<< "$CONTROL_PLANE_AZS";
then
   CONTROL_PLANE_AZS=''
else
   CP_AZS=$(echo "$CONTROL_PLANE_AZS"  | sed 's/"/\\"/g')
fi

if grep -q "null" <<< "$NODEGROUP_AVAILABILITY_ZONES";
then
   NODEGROUP_AVAILABILITY_ZONES=''
else
   NODEGROUP_AZS=$(echo "$NODEGROUP_AVAILABILITY_ZONES"  | sed 's/"/\\"/g')
fi

if grep -q "null" <<< "$NODEGROUP_SECURITY_GROUPS";
then
   NODEGROUP_SECURITY_GROUPS=''
fi


cluster_data='{"name":"'"${CLUSTER_NAME}"'","provider_type":1,"auto_create":true,"cluster_type":"'"${CLUSTER_TYPE}"'","capacity":[],"cluster_blueprint":"'"${CLUSTER_BLUEPRINT}"'","edge_provider_params":{"params":"{\"region\":\"aws/'"${CLUSTER_PROVIDER_REGION}"'\",\"instance_type\":\"'"${NODEGROUP_INSTANCE_TYPE}"'\",\"version\":\"'"${K8S_VERSION}"'\",\"nodes\":'${NODES_DESIRED}',\"nodes_min\":'${NODES_MIN}',\"nodes_max\":'${NODES_MAX}',\"node_volume_type\":\"'"${NODE_VOLUME_TYPE}"'\",\"node_ami_family\":\"'"${NODE_AMI_FAMILY}"'\",\"vpc_nat_mode\":\"'"${NAT_GATEWAY_MODE}"'\",\"vpc_cidr\":\"'"${VPC_CIDR}"'\",\"enable_full_access_to_ecr\":'${IAM_ECR}',\"enable_asg_access\":'${IAM_ASG}',\"managed\":'${NODEGROUP_MANAGED}',\"node_private_networking\":'${NODEGROUP_PRIVATE_NETWORKING}',\"zones\":['"$CP_AZS"'],\"vpc_private_subnets\":['"$PRI_SUBNETS"'],\"vpc_public_subnets\":['"$PUB_SUBNETS"'],\"node_zones\":['"${NODEGROUP_AZS}"'],\"node_ami\":\"'"${NODE_AMI}"'\",\"nodegroup_name\":\"'"${NODEGROUP_NAME}"'\",\"node_security_groups\":['"${NODEGROUP_SECURITY_GROUPS}"'],\"ssh_public_key\":\"'"${NODE_SSH_KEY}"'\"}"},"cloud_provider":"AWS","provider_id":"'"${PROVIDER_ID}"'","ha_enabled":true,"auto_approve_nodes":true,"metro":{"name":"aws/'"${CLUSTER_PROVIDER_REGION}"'"}}'


curl -k -vvvvv -d ${cluster_data} -H "content-type: application/json;charset=UTF-8" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/ -o /tmp/rafay_edge > /tmp/$$_curl 2>&1
grep 'HTTP/2 201'  /tmp/$$_curl > /dev/null 2>&1
[ $? -ne 0 ] && DBG=`cat /tmp/rafay_edge` && echo -e " !! Detected failure adding cluster ${cluster_data} ${DBG}!! Exiting  " && exit -1
rm /tmp/$$_curl
echo "[+] Successfully added cluster ${cluster_data}"
EDGE_ID=`cat /tmp/rafay_edge |jq '.id'|cut -d'"' -f2`
EDGE_STATUS=`cat /tmp/rafay_edge |jq '.status'|cut -d'"' -f2`
CLUSTER_HEALTH=`cat /tmp/rafay_edge |jq '.health'|cut -d'"' -f2`
rm /tmp/rafay_edge
EDGE_STATUS_ITERATIONS=1
CLUSTER_HEALTH_ITERATIONS=1
while [ "$EDGE_STATUS" != "READY" ]
do
  sleep 60
  if [ $EDGE_STATUS_ITERATIONS -ge 50 ];
  then
    break
  fi
  EDGE_STATUS_ITERATIONS=$((EDGE_STATUS_ITERATIONS+1))
  EDGE_STATUS=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.status' |cut -d'"' -f2`
  if [ $EDGE_STATUS == "PROVISION_FAILED" ];
  then
    echo -e " !! Cluster provision failed !!  "
    PROVISION_SUMMARY=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/provision/log/ | jq '.[].provisionSummary' |cut -d'"' -f2`
    PROVISION_FAILURE_SUMMARY=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/provision/log/ | jq '.[].provisionFailureSummary'`
    echo -e "$PROVISION_SUMMARY"
    echo -e "$PROVISION_FAILURE_SUMMARY"
    echo -e " !! Exiting !!  " && exit -1
  fi

  PROVISION_STATUS=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.provision.status' |cut -d'"' -f2`

  if [ $PROVISION_STATUS == "INFRA_CREATION_FAILED" ];
  then
    echo -e " !! Cluster provision failed !!  "
    COMMENTS=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.provision.comments' |cut -d'"' -f2`
    echo -e "$COMMENTS"
    echo -e " !! Exiting !!  " && exit -1
  fi

  PROVISION_STATE=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/provision/progress | jq '.stateName' |cut -d'"' -f2`


  if [ "$PROVISION_STATE" == "null" ];
  then
    echo "Provisioning Node"
  else
    echo "Provisioning ${PROVISION_STATE}"
  fi
done
if [ $EDGE_STATUS != "READY" ];
then
    echo -e " !! Cluster provision failed !!  "
    echo -e " !! Exiting !!  " && exit -1
fi
if [ $EDGE_STATUS == "READY" ];
then
    echo "[+] Cluster Provisioned Successfully waiting for it to be healthy"
    CLUSTER_HEALTH=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.health' |cut -d'"' -f2`
    while [ "$CLUSTER_HEALTH" != 1 ]
    do
      echo "Iteration-${CLUSTER_HEALTH_ITERATIONS} : Waiting 60 seconds for cluster to be healthy..."
      sleep 60
      if [ $CLUSTER_HEALTH_ITERATIONS -ge 15 ];
      then
        break
      fi
      CLUSTER_HEALTH_ITERATIONS=$((CLUSTER_HEALTH_ITERATIONS+1))
      CLUSTER_HEALTH=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.health' |cut -d'"' -f2`
    done
fi

if [[ $CLUSTER_HEALTH == 0 ]];
then
    echo -e " !! Cluster is not healthy !!  "
    echo -e " !! Exiting !!  " && exit -1
fi
if [[ $CLUSTER_HEALTH == 1 ]];
then
    echo "[+] Cluster Provisioned Successfully and is Healthy"
fi

```

--