#!/bin/bash
curl -s -o rctl-linux-amd64.tar.bz2 https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2
tar -xf rctl-linux-amd64.tar.bz2
chmod 0755 rctl

GROUP_NAME=$1
PROJECT_NAME=$2

./rctl delete  groupassociation $GROUP_NAME --dissociateproject $PROJECT_NAME
if [ $? -eq 0 ];
then
    echo "[+] Successfully deleted groupassociation ${GROUP_NAME}"
fi
