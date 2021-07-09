#!/bin/bash
#curl -s -o rctl-linux-amd64.tar.bz2 https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2
#tar -xf rctl-linux-amd64.tar.bz2
#chmod 0755 rctl

./rctl get credential  $CRED_NAME -p $PROJECT_NAME > /dev/null 2>&1
if [ $? -eq 0 ];
then
	echo "[+]  ${PROJECT_NAME} project already contains ${CRED_NAME}"
	exit 0
fi

./rctl create credential aws $CRED_NAME --cred-type "cluster-provisioning" --role-arn $ROLEARN_VALUE -p $PROJECT_NAME --external-id $EXTERNAL_ID
if [ $? -eq 0 ];
then 
	echo "[+] Successfully Created Credential Name of ${CRED_NAME} in the project ${PROJECT_NAME}"
	exit 0
fi

