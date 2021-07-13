#!/bin/bash
curl -s -o rctl-linux-amd64.tar.bz2 https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2
tar -xf rctl-linux-amd64.tar.bz2
chmod 0755 rctl
GROUP_NAME=$1
./rctl get group $GROUP_NAME > /dev/null 2>&1
if [ $? -eq 1 ];
then
	echo "[+] ${GROUP_NAME} does not exist"
	exit 0
fi

./rctl delete group $GROUP_NAME
if [ $? -eq 0 ];
then
    echo "[+] Successfully deleted ${GROUP_NAME}"
fi
