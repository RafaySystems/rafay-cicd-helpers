#!/bin/bash

SCRIPT='rafay_imported_cluster.sh'

function HELP {
  echo -e "\nUsage: $SCRIPT [-u <Username>] [-p <Password>] [-f <cluster meta file>] -a"
  echo -e "\t-u  Username to login to the Rafay Console"
  echo -e "\t-p  Password to login to the Rafay Console"
  echo -e "\t-f  cluster meta file"
  echo -e "\t-a  Optional argument to indicate if kubectl should be applied"
  echo
  echo -e "\nExample:  $SCRIPT -u test@example.com -p test123 -f cluster_meta.yaml -a"
  echo
  exit 1
}

NUMARGS=$#
if [ $NUMARGS -eq 0 ]; then
  HELP
fi

KUBECTL_APPLY=FALSE

while getopts :u:p:f:ah FLAG; do
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
    a)
      KUBECTL_APPLY=TRUE
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
CLUSTER_NAME=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.name' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_PROVIDER_REGION=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.region' | tr \" " " | awk '{print $1}' | tr -d "\n"`
CLUSTER_BLUEPRINT=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.blueprint' | tr \" " " | awk '{print $1}' | tr -d "\n"`
PROJECT=`cat ${CLUSTER_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.project' | tr \" " " | awk '{print $1}' | tr -d "\n"`


if [ $CLUSTER_TYPE != "imported" ];
then
    echo "Valid input for kind is "imported" !! Exiting" && exit -1
fi


curl -k -vvvv -d ${USERDATA} -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8"  -X POST  https://${OPS_HOST}/auth/v1/login/ > /tmp/$$_curl 2>&1
csrf_token=`grep -inr "set-cookie: csrftoken" /tmp/$$_curl |  cut -d'=' -f2 | cut -d';' -f1`
rsid=`grep -inr "set-cookie: rsid" /tmp/$$_curl |  cut -d'=' -f2 | cut -d';' -f1`
rm /tmp/$$_curl

curl -k -vvvvv -H "content-type: application/json;charset=UTF-8" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/metros/ -o /tmp/rafay_locations > /tmp/$$_curl 2>&1

grep -i ubuntu /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
then
    grep 'HTTP/2 200'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_locations` && echo -e " !! Failure in  getting locations ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
fi
grep -i centos /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
then
    grep 'HTTP/1.1 200'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_locations` && echo -e " !! Failure in  getting locations ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
fi

METROS=`cat /tmp/rafay_locations |jq '.results[] | .name'|cut -d'"' -f2`
rm /tmp/rafay_locations
METROS_ARRAY=( $METROS )

LookupMetro () {
  local metro match="$1"
  shift
  for metro; do [[ "$metro" == "$match" ]] && return 0; done
  return 1
}
LOCATION=`echo $CLUSTER_PROVIDER_REGION |tr '[:upper:]' '[:lower:]'`
LookupMetro $LOCATION "${METROS_ARRAY[@]}"
[ $? -ne 0 ] && echo -e " !! Could not find the region with the name ${LOCATION}\n Please specify any of the below listed regions \n $METROS !! Exiting  " && exit -1


projects=`curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/auth/v1/projects/ | jq '.results[]|.name,.id' |cut -d'"' -f2`


PROJECTS_ARRAY=( $projects )
LookupMetro $PROJECT "${PROJECTS_ARRAY[@]}"
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


cluster_data='{"name":"'"${CLUSTER_NAME}"'","ha_enabled":false,"gpu_enabled":false,"gpu_vendor":"","cluster_type":"'"${CLUSTER_TYPE}"'","capacity":[],"cluster_blueprint":"'"${CLUSTER_BLUEPRINT}"'","edge_provider_params":{"params":"{}"},"metro":{"name":"'"${CLUSTER_PROVIDER_REGION}"'"},"labels":{}}'


curl -k -vvvvv -d ${cluster_data} -H "content-type: application/json;charset=UTF-8" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/ -o /tmp/rafay_edge > /tmp/$$_curl 2>&1
grep -i ubuntu /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
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
rm /tmp/os
echo "[+] Successfully added cluster ${cluster_data}"
EDGE_ID=`cat /tmp/rafay_edge |jq '.id'|cut -d'"' -f2`
EDGE_STATUS=`cat /tmp/rafay_edge |jq '.status'|cut -d'"' -f2`
CLUSTER_HEALTH=`cat /tmp/rafay_edge |jq '.health'|cut -d'"' -f2`
rm /tmp/rafay_edge
EDGE_STATUS_ITERATIONS=1
CLUSTER_HEALTH_ITERATIONS=1

sleep 60
curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/v2/scheduler/project/${PROJECT_ID}/cluster/${CLUSTER_NAME}/download -o /tmp/${CLUSTER_NAME}.yaml > /tmp/$$_curl 2>&1

if [ $KUBECTL_APPLY == "TRUE" ];
then
    echo "Applying bootstrap to the cluster"
    kubectl apply -f /tmp/${CLUSTER_NAME}.yaml
    echo "[+] Bootstrap apply completed... Waiting for the sync to complete"
else
    echo "Please apply the bootstrap yaml file on the cluster using kubectl. Bootstrap file is located at /tmp/${CLUSTER_NAME}.yaml"
fi

while [ "$EDGE_STATUS" != "READY" ]
do
  sleep 60
  if [ $EDGE_STATUS_ITERATIONS -ge 50 ];
  then
    break
  fi
  EDGE_STATUS_ITERATIONS=$((EDGE_STATUS_ITERATIONS+1))
  EDGE_STATUS=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.status' |cut -d'"' -f2`
  REGISTER_STATUS=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.cluster.status.conditions[0].status' |cut -d'"' -f2`
  CHECKIN_STATUS=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.cluster.status.conditions[2].status' |cut -d'"' -f2`
  NAMESPACE_STATUS=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.cluster.status.conditions[5].status' |cut -d'"' -f2`
  BLUEPRINT_STATUS=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.cluster.status.conditions[4].status' |cut -d'"' -f2`
  if [ $REGISTER_STATUS == "Success" ];
  then
    echo " Cluster Registered Successfully"
  fi
  if [ $CHECKIN_STATUS == "Success" ];
  then
    echo " Cluster Checked in Successfully"
  fi
  if [ $NAMESPACE_STATUS == "Success" ];
  then
    echo " Namespace synced Successfully to Cluster"
  elif [ $NAMESPACE_STATUS == "InProgress" ];
  then
    echo " Namespace sync in progress"
  elif [ $NAMESPACE_STATUS == "Pending" ];
  then
    echo " Namespace sync Pending"
  fi
  if [ $BLUEPRINT_STATUS == "Success" ];
  then
    echo " Blueprint synced Successfully to Cluster"
  elif [ $BLUEPRINT_STATUS == "InProgress" ];
  then
    echo " Blueprint sync in progress"
  elif [ $BLUEPRINT_STATUS == "Pending" ];
  then
    echo " Blueprint sync Pending"
  elif [ $BLUEPRINT_STATUS == "Failed" ];
  then
     echo -e " !! Blueprint sync failed !!  "
     BLUEPRINT_FAILED_REASON=`curl -k -s -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/edge/v1/projects/${PROJECT_ID}/edges/${EDGE_ID}/ | jq '.cluster.status.conditions[4].reason'`
     echo -e "$BLUEPRINT_FAILED_REASON"
     echo -e " !! Exiting !!  " && exit -1
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
