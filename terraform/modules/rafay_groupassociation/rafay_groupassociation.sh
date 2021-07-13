#!/bin/bash
curl -s -o rctl-linux-amd64.tar.bz2 https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2
tar -xf rctl-linux-amd64.tar.bz2
chmod 0755 rctl

./rctl create groupassociation $GROUP_NAME --associateproject  $PROJECT_NAME --roles  $ROLES
if [ $? -eq 0 ];
then
    echo "[+] Successfully associated project $PROJECT_NAME to group ${GROUP_NAME} with roles $ROLES"
fi
