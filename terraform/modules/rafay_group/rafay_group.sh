#!/bin/bash
curl -s -o rctl-linux-amd64.tar.bz2 https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2
tar -xf rctl-linux-amd64.tar.bz2
chmod 0755 rctl

./rctl get group $GROUP_NAME > /dev/null 2>&1
if [ $? -eq 0 ];
then
	echo "[+] ${GROUP_NAME} already exists"
	exit 0
fi

./rctl create group $GROUP_NAME
if [ $? -eq 0 ];
then
    echo "[+] Successfully Created new ${GROUP_NAME}"
fi
