#!/bin/bash

SCRIPT='rafay_addon.sh'

function HELP {
  echo -e "\nUsage: $SCRIPT [-u <Username>] [-p <Password>] [-f <addon meta file>] "
  echo -e "\t-u  Username to login to the Rafay Console"
  echo -e "\t-p  Password to login to the Rafay Console"
  echo -e "\t-f  addon meta file"
  echo
  echo -e "\nExample:  $SCRIPT -u test@example.com -p test123 -f addon_meta.yaml"
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
      ADDON_META_FILE=$OPTARG
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

ADDON_NAME=`cat ${ADDON_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.name' | tr \" " " | awk '{print $1}' | tr -d "\n"`
ADDON_TYPE=`cat ${ADDON_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.type' | tr \" " " | awk '{print $1}' | tr -d "\n"`
ADDON_NAMESPACE=`cat ${ADDON_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.namespace' | tr \" " " | awk '{print $1}' | tr -d "\n"`
ADDON_FILENAME=`cat ${ADDON_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.payload' | tr \" " " | awk '{print $1}' | tr -d "\n"`
ADDON_VAULES=`cat ${ADDON_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.values' | tr \" " " | awk '{print $1}' | tr -d "\n"`
cat ${ADDON_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | grep -w "version:" > /dev/null 2>&1
if [ $? -ne 0 ];
then
    ADDON_VERSION="v1"
else
    ADDON_VERSION=`cat ${ADDON_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.version' | tr \" " " | awk '{print $1}' | tr -d "\n"`
fi
PROJECT=`cat ${ADDON_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.project' | tr \" " " | awk '{print $1}' | tr -d "\n"`


case $ADDON_TYPE in
  (Helm|NativeYaml) ;;
  (*) echo "Valid input for ADDON_TYPE is "Helm" or "NativeYaml" !! Exiting" && exit -1;;
esac


curl -k -vvvv -d ${USERDATA} -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8"  -X POST  https://${OPS_HOST}/auth/v1/login/ > /tmp/$$_curl 2>&1
csrf_token=`grep -inr "set-cookie: csrftoken" /tmp/$$_curl |  cut -d'=' -f2 | cut -d';' -f1`
rsid=`grep -inr "set-cookie: rsid" /tmp/$$_curl |  cut -d'=' -f2 | cut -d';' -f1`
rm /tmp/$$_curl

LookupProjects () {
  local cluster match="$1"
  shift
  for cluster; do [[ "$cluster" == "$match" ]] && return 0; done
  return 1
}

projects=`curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/auth/v1/projects/ | jq '.results[]|.name,.id' |cut -d'"' -f2`


PROJECTS_ARRAY=( $projects )
LookupProjects $PROJECT "${PROJECTS_ARRAY[@]}"
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

namespaces=`curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/config/v1/projects/${PROJECT_ID}/namespaces/?limit=100 | jq '.results[]|.name' |cut -d'"' -f2`


NAMESPACES_ARRAY=( $namespaces )
LookupProjects $ADDON_NAMESPACE "${NAMESPACES_ARRAY[@]}"
if [ $? -ne 0 ];
then
    echo -e " !! Could not find the namespace with the name $ADDON_NAMESPACE, creating now !!"
    namespace_data='{"name":"'"${ADDON_NAMESPACE}"'","description":"","project_id":"'"${PROJECT_ID}"'"}'
    curl -k -vvvvv -d ${namespace_data} -H "content-type: application/json;charset=UTF-8" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/config/v1/projects/${PROJECT_ID}/namespaces/ -o /tmp/rafay_namespace > /tmp/$$_curl 2>&1
    grep -i ubuntu /tmp/os > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        grep 'HTTP/2 201'  /tmp/$$_curl > /dev/null 2>&1
        [ $? -ne 0 ] && DBG=`cat /tmp/rafay_namespace` && echo -e " !! Detected failure adding namespace ${ADDON_NAMESPACE} ${DBG}!! Exiting  " && exit -1
        rm /tmp/$$_curl
        echo "[+] Successfully added namespace ${ADDON_NAMESPACE}"
    fi
    grep -i centos /tmp/os > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        grep 'HTTP/1.1 201'  /tmp/$$_curl > /dev/null 2>&1
        [ $? -ne 0 ] && DBG=`cat /tmp/rafay_namespace` && echo -e " !! Detected failure adding namespace ${ADDON_NAMESPACE} ${DBG}!! Exiting  " && exit -1
        rm /tmp/$$_curl
        echo "[+] Successfully added namespace ${ADDON_NAMESPACE}"
    fi
fi


addon_data='{"name":"'"${ADDON_NAME}"'","namespace":"'"${ADDON_NAMESPACE}"'","type":"'"${ADDON_TYPE}"'"}'


curl -k -vvvvv -d ${addon_data} -H "content-type: application/json;charset=UTF-8" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/config/v1/projects/${PROJECT_ID}/systemworkloads/ -o /tmp/rafay_addon > /tmp/$$_curl 2>&1
grep -i ubuntu /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
then
    grep 'HTTP/2 201'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_addon` && echo -e " !! Detected failure adding addon ${addon_data} ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
    echo "[+] Successfully added addon ${addon_data}"
fi
grep -i centos /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
then
    grep 'HTTP/1.1 201'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_addon` && echo -e " !! Detected failure adding addon ${addon_data} ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
    echo "[+] Successfully added addon ${addon_data}"
fi
UPLOAD_LINK=`cat /tmp/rafay_addon |jq '.upload_link'|cut -d'"' -f2`
if [ $ADDON_TYPE == "Helm" ];
then
    UPLOAD_VALUES_LINK=`cat /tmp/rafay_addon |jq '.upload_values_link'|cut -d'"' -f2`
fi
ADDON_ID=`cat /tmp/rafay_addon |jq '.id'|cut -d'"' -f2`
rm /tmp/rafay_addon

curl -k -vvvvv -F payload="@$ADDON_FILENAME" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/${UPLOAD_LINK} -o /tmp/rafay_addon_payload > /tmp/$$_curl 2>&1
grep -i ubuntu /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
then
    grep 'HTTP/2 200'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_addon_payload` && echo -e " !! Detected failure uploading ${ADDON_FILENAME} ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
    rm /tmp/rafay_addon_payload
fi
grep -i centos /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
then
    grep 'HTTP/1.1 200'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_addon_payload` && echo -e " !! Detected failure uploading ${ADDON_FILENAME} ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
    rm /tmp/rafay_addon_payload
fi

if [ $ADDON_TYPE == "Helm" ];
then
    curl -k -vvvvv -F values="@$ADDON_VAULES" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/${UPLOAD_VALUES_LINK} -o /tmp/rafay_addon_values > /tmp/$$_curl 2>&1
    grep -i ubuntu /tmp/os > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        grep 'HTTP/2 200'  /tmp/$$_curl > /dev/null 2>&1
        [ $? -ne 0 ] && DBG=`cat /tmp/rafay_addon_values` && echo -e " !! Detected failure uploading ${ADDON_VAULES} ${DBG}!! Exiting  " && exit -1
        rm /tmp/$$_curl
        rm /tmp/rafay_addon_values
     fi
    grep -i centos /tmp/os > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
        grep 'HTTP/1.1 200'  /tmp/$$_curl > /dev/null 2>&1
        [ $? -ne 0 ] && DBG=`cat /tmp/rafay_addon_values` && echo -e " !! Detected failure uploading ${ADDON_VAULES} ${DBG}!! Exiting  " && exit -1
        rm /tmp/$$_curl
        rm /tmp/rafay_addon_values
    fi
fi

addon_version_data='{"version":"'"${ADDON_VERSION}"'"}'
curl -k -vvvvv -d ${addon_version_data} -H "content-type: application/json;charset=UTF-8" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/config/v1/projects/${PROJECT_ID}/systemworkloads/${ADDON_ID}/publish/ -o /tmp/rafay_addon_publish > /tmp/$$_curl 2>&1
grep -i ubuntu /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
then
    grep 'HTTP/2 200'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_addon_publish` && echo -e " !! Detected failure publishing addon ${ADDON_NAME} ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
    rm /tmp/rafay_addon_publish
fi
grep -i centos /tmp/os > /dev/null 2>&1
if [ $? -eq 0 ];
then
    grep 'HTTP/1.1 200'  /tmp/$$_curl > /dev/null 2>&1
    [ $? -ne 0 ] && DBG=`cat /tmp/rafay_addon_publish` && echo -e " !! Detected failure publishing addon ${ADDON_NAME} ${DBG}!! Exiting  " && exit -1
    rm /tmp/$$_curl
    rm /tmp/rafay_addon_publish
fi
rm /tmp/os
echo "[+] Successfully published addon ${ADDON_NAME}"

