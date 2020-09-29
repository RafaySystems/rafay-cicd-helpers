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
    hostnamectl > /tmp/os
    grep -i ubuntu /tmp/os > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        #Install jq if not installed
        JQ_PKG_OK=$(dpkg-query -W --showformat='${Status}\n' jq|grep "install ok installed")
        echo Checking for jq package: $JQ_PKG_OK
        if [ "" == "$JQ_PKG_OK" ]; then
            echo "jq package not installed. Installing jq..."
            sudo apt-get -y update > /dev/null
            sudo apt-get -y install jq
        fi

        #Install curl if not installed
        CURL_PKG_OK=$(dpkg-query -W --showformat='${Status}\n' curl|grep "install ok installed")
        echo Checking for curl package: $CURL_PKG_OK
        if [ "" == "$CURL_PKG_OK" ]; then
            echo "curl package not installed. Installing curl..."
            sudo apt-get -y update > /dev/null
            sudo apt-get -y install curl
        fi
    fi
    grep -i centos /tmp/os > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        #Install jq if not installed
        IS_JQ_INSTALLED=$(rpm -q jq)
        if [ "$IS_JQ_INSTALLED" == "package jq is not installed" ];
        then
            echo "jq package not installed. Installing jq..."
            sudo yum install -y epel-release
            sudo yum install -y jq
        fi
        #Install curl if not installed
        IS_CURL_INSTALLED=$(rpm -q curl)
        if [ "$IS_CURL_INSTALLED" == "package curl is not installed" ];
        then
            echo "curl package not installed. Installing curl..."
            sudo yum install -y curl
        fi
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
ENDPOINT_PUBLIC_ACCESS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.controlPlane.clusterEndpoints.publicAccess' | tr \" " " | awk '{print $1}' | tr -d "\n"`
ENDPOINT_PRIVATE_ACCESS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.controlPlane.clusterEndpoints.privateAccess' | tr \" " " | awk '{print $1}' | tr -d "\n"`



if [ $CLUSTER_TYPE != "AmazonEKS" ];
then
    echo "Valid input for kind is "AmazonEKS" !! Exiting" && exit -1
fi

case $K8S_VERSION in
  ("1.15"|"1.16") ;;
  (*) echo "Valid input for general.k8sVersion is "1.15" or "1.16" !! Exiting" && exit -1;;
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
  (AmazonLinux2|Ubuntu1804|Bottlerocket|null) ;;
  (*) echo "Valid input for nodeGroups.amiFamily is "AmazonLinux2", "Ubuntu1804", "Bottlerocket" !! Exiting" && exit -1;;
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

projects=`curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/auth/v1/projects/?limit=100 | jq '.results[]|.name,.id' |cut -d'"' -f2`


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

providers=`curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/providers/?limit=100 | jq '.results[]|.name,.ID' |cut -d'"' -f2`


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
else
   NODE_SECURITY_GROUPS=$(echo "$NODEGROUP_SECURITY_GROUPS"  | sed 's/"/\\"/g')
fi

if [[ "$ENDPOINT_PUBLIC_ACCESS" == false  &&  "$ENDPOINT_PRIVATE_ACCESS" == true ]];
then
    ENDPOINT_ACCESS_CONFIG='\"cluster_endpoint_access_type\":\"private\",\"private_access\":\"true\",\"public_access\":\"false\"'
fi

if [[ "$ENDPOINT_PUBLIC_ACCESS" == true  &&  "$ENDPOINT_PRIVATE_ACCESS" == false ]];
then
    ENDPOINT_ACCESS_CONFIG='\"cluster_endpoint_access_type\":\"public\",\"private_access\":\"false\",\"public_access\":\"true\"'
fi

if [[ "$ENDPOINT_PUBLIC_ACCESS" == true  &&  "$ENDPOINT_PRIVATE_ACCESS" == true ]];
then
    ENDPOINT_ACCESS_CONFIG='\"cluster_endpoint_access_type\":\"private_and_public\",\"private_access\":\"true\",\"public_access\":\"true\"'
fi


cluster_data='{"name":"'"${CLUSTER_NAME}"'","provider_type":1,"auto_create":true,"cluster_type":"'"${CLUSTER_TYPE}"'","capacity":[],"cluster_blueprint":"'"${CLUSTER_BLUEPRINT}"'","edge_provider_params":{"params":"{\"region\":\"aws/'"${CLUSTER_PROVIDER_REGION}"'\",\"instance_type\":\"'"${NODEGROUP_INSTANCE_TYPE}"'\",\"version\":\"'"${K8S_VERSION}"'\",\"nodes\":'${NODES_DESIRED}',\"nodes_min\":'${NODES_MIN}',\"nodes_max\":'${NODES_MAX}',\"node_volume_type\":\"'"${NODE_VOLUME_TYPE}"'\",\"node_ami_family\":\"'"${NODE_AMI_FAMILY}"'\",\"vpc_nat_mode\":\"'"${NAT_GATEWAY_MODE}"'\",\"vpc_cidr\":\"'"${VPC_CIDR}"'\",\"enable_full_access_to_ecr\":'${IAM_ECR}',\"enable_asg_access\":'${IAM_ASG}',\"managed\":'${NODEGROUP_MANAGED}',\"node_private_networking\":'${NODEGROUP_PRIVATE_NETWORKING}',\"zones\":['"$CP_AZS"'],\"vpc_private_subnets\":['"$PRI_SUBNETS"'],\"vpc_public_subnets\":['"$PUB_SUBNETS"'],\"node_zones\":['"${NODEGROUP_AZS}"'],\"node_ami\":\"'"${NODE_AMI}"'\",\"nodegroup_name\":\"'"${NODEGROUP_NAME}"'\",\"node_security_groups\":['"${NODE_SECURITY_GROUPS}"'],\"ssh_public_key\":\"'"${NODE_SSH_KEY}"'\",'${ENDPOINT_ACCESS_CONFIG}'}"},"cloud_provider":"AWS","provider_id":"'"${PROVIDER_ID}"'","ha_enabled":true,"auto_approve_nodes":true,"metro":{"name":"aws/'"${CLUSTER_PROVIDER_REGION}"'"}}'


curl -k -vvvvv -d ${cluster_data} -H "content-type: application/json;charset=UTF-8" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/ -o /tmp/rafay_edge > /tmp/$$_curl 2>&1
grep -i ubuntu /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ] || [[ "$OSTYPE" == "darwin"* ]];
then
    grep 'HTTP/2 201'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_edge` && echo -e " !! Detected failure adding cluster ${cluster_data} ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
fi
grep -i centos /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
then
    grep 'HTTP/1.1 201'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_edge` && echo -e " !! Detected failure adding cluster ${cluster_data} ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
fi
if [ -f /tmp/os ];
then
    rm /tmp/os
fi
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

  if [ $PROVISION_STATUS == "BOOTSTRAP_CREATION_FAILED" ];
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




