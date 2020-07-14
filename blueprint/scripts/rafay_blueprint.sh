#!/bin/bash

SCRIPT='rafay_blueprint.sh'

function HELP {
  echo -e "\nUsage: $SCRIPT [-u <Username>] [-p <Password>] [-f <blueprint meta file>] "
  echo -e "\t-u  Username to login to the Rafay Console"
  echo -e "\t-p  Password to login to the Rafay Console"
  echo -e "\t-f  addon meta file"
  echo
  echo -e "\nExample:  $SCRIPT -u test@example.com -p test123 -f blueprint_meta.yaml"
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
      BLUEPRINT_META_FILE=$OPTARG
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
    rm /tmp/os
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

BLUEPRINT_NAME=`cat ${BLUEPRINT_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.name' | tr \" " " | awk '{print $1}' | tr -d "\n"`
RAFAY_INGRESS=`cat ${BLUEPRINT_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.rafay_ingress' | tr \" " " | awk '{print $1}' | tr -d "\n"`
ADDONS=`cat ${BLUEPRINT_META_FILE} | python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.addons' |tr "[" " "|tr "]" " " | tr \" " "|tr "," " "`
ADDON_FILENAME=`cat ${BLUEPRINT_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.payload' | tr \" " " | awk '{print $1}' | tr -d "\n"`
ADDON_VAULES=`cat ${BLUEPRINT_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.values' | tr \" " " | awk '{print $1}' | tr -d "\n"`
cat ${BLUEPRINT_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | grep -w "version:" > /dev/null 2>&1
if [ $? -ne 0 ];
then
    BLUEPRINT_VERSION="v1"
else
    BLUEPRINT_VERSION=`cat ${BLUEPRINT_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.version' | tr \" " " | awk '{print $1}' | tr -d "\n"`
fi
PROJECT=`cat ${BLUEPRINT_META_FILE} | $python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq '.project' | tr \" " " | awk '{print $1}' | tr -d "\n"`


case $RAFAY_INGRESS in
  (true|false) ;;
  (*) echo "Valid input for RAFAY_INGRESS is "true" or "false" !! Exiting" && exit -1;;
esac


curl -k -vvvv -d ${USERDATA} -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8"  -X POST  https://${OPS_HOST}/auth/v1/login/ > /tmp/$$_curl 2>&1
csrf_token=`grep -inr "set-cookie: csrftoken" /tmp/$$_curl |  cut -d'=' -f2 | cut -d';' -f1`
rsid=`grep -inr "set-cookie: rsid" /tmp/$$_curl |  cut -d'=' -f2 | cut -d';' -f1`
rm /tmp/$$_curl

Lookupaddons () {
  local addon match="$1"
  shift
  for addon; do [[ "$addon" == "$match" ]] && return 0; done
  return 1
}

projects=`curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/auth/v1/projects/ | jq '.results[]|.name,.id' |cut -d'"' -f2`


PROJECTS_ARRAY=( $projects )
Lookupaddons $PROJECT "${PROJECTS_ARRAY[@]}"
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

addons=`curl -k -s -H "x-rafay-partner: rx28oml" -H "content-type: application/json;charset=UTF-8" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/config/v1/projects/${PROJECT_ID}/systemworkloads/?limit=1000 | jq '.results[]|.name' |cut -d'"' -f2`
CUSTOM_COMPONENTS=''
ADDONS_CONFIGURED_ARRAY=( $ADDONS )
ADDONS_ARRAY=( $addons )
for i in "${!ADDONS_CONFIGURED_ARRAY[@]}";
do
    if [ ${ADDONS_CONFIGURED_ARRAY[$i]} == "null" ];
    then
        echo "No Addons configured !! Exiting" && exit -1
    else
        Lookupaddons ${ADDONS_CONFIGURED_ARRAY[$i]} "${ADDONS_ARRAY[@]}"
        [ $? -ne 0 ] && echo -e " !! Could not find the addon with the name ${ADDONS_CONFIGURED_ARRAY[$i]} !! Exiting  " && exit -1
        CUSTOM_COMPONENTS+='{"name":"'"${ADDONS_CONFIGURED_ARRAY[$i]}"'"},'
    fi
done

CUSTOM_COMPONENTS=`echo $CUSTOM_COMPONENTS |sed 's/,*$//'`

if [ $RAFAY_INGRESS == "false" ];
then
    EXCLUDED_COMPONENTS='{"name":"v1-ingress-infra"},{"name":"v2-ingress-infra"}'
elif [ $RAFAY_INGRESS == "true" ];
then
    EXCLUDED_COMPONENTS=''
fi

blueprint_data='{"metadata":{"name":"'"${BLUEPRINT_NAME}"'"},"spec":{"excludedSystemComponents":['${EXCLUDED_COMPONENTS}'],"customComponents":['${CUSTOM_COMPONENTS}']}}'

curl -k -vvvvv -d ${blueprint_data} -H "content-type: application/json;charset=UTF-8" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/v2/config/project/${PROJECT_ID}/blueprint -o /tmp/rafay_blueprint > /tmp/$$_curl 2>&1
grep 'HTTP/2 200'  /tmp/$$_curl > /dev/null 2>&1
[ $? -ne 0 ] && DBG=`cat /tmp/rafay_blueprint` && echo -e " !! Detected failure adding blueprint ${blueprint_data} ${DBG}!! Exiting  " && exit -1
rm /tmp/$$_curl
echo "[+] Successfully added blueprint ${blueprint_data}"

blueprint_version_data='{"snapshotDisplayName":"'"${BLUEPRINT_VERSION}"'"}'
curl -k -vvvvv -d ${blueprint_version_data} -H "content-type: application/json;charset=UTF-8" -H "referer: https://${OPS_HOST}/" -H "x-rafay-partner: rx28oml" -H "x-csrftoken: ${csrf_token}" -H "cookie: partnerID=rx28oml; csrftoken=${csrf_token}; rsid=${rsid}" https://${OPS_HOST}/v2/config/project/${PROJECT_ID}/blueprint/${BLUEPRINT_NAME}/publish -o /tmp/rafay_blueprint_publish > /tmp/$$_curl 2>&1
grep 'HTTP/2 200'  /tmp/$$_curl > /dev/null 2>&1
[ $? -ne 0 ] && DBG=`cat /tmp/rafay_blueprint_publish` && echo -e " !! Detected failure publishing blueprint ${BLUEPRINT_NAME} ${DBG}!! Exiting  " && exit -1
rm /tmp/$$_curl
rm /tmp/rafay_blueprint_publish
echo "[+] Successfully published blueprint ${BLUEPRINT_NAME}"

