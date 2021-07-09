#! /bin/bash
curl -s -o rctl-linux-amd64.tar.bz2  https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2
tar -xf rctl-linux-amd64.tar.bz2
chmod 0755 rctl
./rctl delete project $1 
