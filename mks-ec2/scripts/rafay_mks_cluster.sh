#!/bin/bash

SCRIPT='rafay_mks_cluster.sh'

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

CLUSTER_NAME=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.cluster_name' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_TYPE=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.cluster_type' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_PROVIDER_REGION=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.cluster_provider_region' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_PROVIDER_CREDENTIALS=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.cluster_provider_credentials' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_INSTANCE_TYPE=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.cluster_instance_type' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_MULTI_MASTER=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.cluster_multi_master' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_GPU_PROVISION=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.cluster_gpu_provision' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_BLUEPRINT=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.cluster_blueprint' | tr \" " " | awk '{print $1}' | tr -d "\n"`
PROJECT=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.project' | tr \" " " | awk '{print $1}' | tr -d "\n"`


if [ $CLUSTER_TYPE != "aws-ec2" ];
then
    echo "Valid input for cluster_type is "aws-ec2" !! Exiting" && exit -1
fi

case $CLUSTER_MULTI_MASTER in
  (true|false) ;;
  (*) echo "Valid input for cluster_multi_master is "true" or "false" !! Exiting" && exit -1;;
esac

case $CLUSTER_GPU_PROVISION in
  (true|false) ;;
  (*) echo "Valid input for cluster_gpu_provision is "true" or "false" !! Exiting" && exit -1;;
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

if [ ${CLUSTER_MULTI_MASTER} == "true" ] && [ $CLUSTER_GPU_PROVISION == "false" ];
then
    cluster_data='{"ha_enabled":true,"gpu_enabled":false,"gpu_vendor":"","cluster_blueprint":"'"${CLUSTER_BLUEPRINT}"'","capacity":[],"edge_provider_params":{"params":"{\"region\":\"aws/'"${CLUSTER_PROVIDER_REGION}"'\",\"instance_type\":\"'"${CLUSTER_INSTANCE_TYPE}"'\"}"},"name":"'"${CLUSTER_NAME}"'","auto_create":true,"cluster_type":"aws-ec2","cloud_provider":"aws","provider_id":"'"${PROVIDER_ID}"'","provider_type":1,"labels":{},"auto_approve_nodes":true,"metro":{"name":"aws/'"${CLUSTER_PROVIDER_REGION}"'"}}'
elif [ ${CLUSTER_MULTI_MASTER} == "false" ] && [ $CLUSTER_GPU_PROVISION == "false" ];
then
    cluster_data='{"ha_enabled":false,"gpu_enabled":false,"gpu_vendor":"","cluster_blueprint":"'"${CLUSTER_BLUEPRINT}"'","capacity":[],"edge_provider_params":{"params":"{\"region\":\"aws/'"${CLUSTER_PROVIDER_REGION}"'\",\"instance_type\":\"'"${CLUSTER_INSTANCE_TYPE}"'\"}"},"name":"'"${CLUSTER_NAME}"'","auto_create":true,"cluster_type":"aws-ec2","cloud_provider":"aws","provider_id":"'"${PROVIDER_ID}"'","provider_type":1,"labels":{},"auto_approve_nodes":true,"metro":{"name":"aws/'"${CLUSTER_PROVIDER_REGION}"'"}}'
elif [ ${CLUSTER_MULTI_MASTER} == "false" ] && [ $CLUSTER_GPU_PROVISION == "true" ];
then
    cluster_data='{"ha_enabled":false,"gpu_enabled":true,"gpu_vendor":"","cluster_blueprint":"'"${CLUSTER_BLUEPRINT}"'","capacity":[],"edge_provider_params":{"params":"{\"region\":\"aws/'"${CLUSTER_PROVIDER_REGION}"'\",\"instance_type\":\"'"${CLUSTER_INSTANCE_TYPE}"'\"}"},"name":"'"${CLUSTER_NAME}"'","auto_create":true,"cluster_type":"aws-ec2","cloud_provider":"aws","provider_id":"'"${PROVIDER_ID}"'","provider_type":1,"labels":{},"auto_approve_nodes":true,"metro":{"name":"aws/'"${CLUSTER_PROVIDER_REGION}"'"}}'
elif [ ${CLUSTER_MULTI_MASTER} == "true" ] && [ $CLUSTER_GPU_PROVISION == "true" ];
then
    cluster_data='{"ha_enabled":true,"gpu_enabled":true,"gpu_vendor":"","cluster_blueprint":"'"${CLUSTER_BLUEPRINT}"'","capacity":[],"edge_provider_params":{"params":"{\"region\":\"aws/'"${CLUSTER_PROVIDER_REGION}"'\",\"instance_type\":\"'"${CLUSTER_INSTANCE_TYPE}"'\"}"},"name":"'"${CLUSTER_NAME}"'","auto_create":true,"cluster_type":"aws-ec2","cloud_provider":"aws","provider_id":"'"${PROVIDER_ID}"'","provider_type":1,"labels":{},"auto_approve_nodes":true,"metro":{"name":"aws/'"${CLUSTER_PROVIDER_REGION}"'"}}'
fi

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
  #echo "Iteration-${EDGE_STATUS_ITERATIONS} : Waiting 60 seconds for cluster to be provisioned..."
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

  if [ $EDGE_STATUS == "PRETEST_FAILED" ];
  then
    echo -e " !! Cluster provision failed !!  "
    PRETEST_SUMMARY=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/provision/log/ | jq '.[].pretestSummary' |cut -d'"' -f2`
    PRETEST_FAILURE_SUMMARY=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/provision/log/ | jq '.[].pretestFailureSummary'`
    echo -e "$PRETEST_SUMMARY"
    echo -e "$PRETEST_FAILURE_SUMMARY"
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


