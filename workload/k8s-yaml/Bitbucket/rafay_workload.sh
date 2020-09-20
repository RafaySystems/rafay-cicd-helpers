#!/bin/bash
if [ $# -eq 0 ]; then
    echo "No arguments provided, WORKLOAD_NAME and WORKLOAD_NAMESPACE needs to be provided as arguments"
    echo "Ex: rafay_workload.sh workload_name namespace_name"
    exit 1
fi
WORKLOAD_NAME=$1
WORKLOAD_NAMESPACE=$2
echo "Create and publish Workload"
wget -q https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2
tar -xf rctl-linux-amd64.tar.bz2
chmod 0755 rctl
echo $WORKLOAD_NAMESPACE
echo $WORKLOAD_NAME
LookupWorkload () {
local workload match="$1"
shift
for workload; do [[ "$workload" == "$match" ]] && return 0; done
return 1
}
./rctl namespace list > /tmp/namespace
grep -i $WORKLOAD_NAMESPACE /tmp/namespace > /dev/null 2>&1
if [ $? -eq 1 ]; then
./rctl namespace create ./namespace-spec.yaml
fi
rm /tmp/namespace
wl_tmp=`./rctl workload list -o json | jq '.result[]|.name' |cut -d'"' -f2`
WL_TMP_ARRAY=( $wl_tmp )
set +e
LookupWorkload $WORKLOAD_NAME "${WL_TMP_ARRAY[@]}"
if [ $? -eq 1 ]; then
 set -e
 ./rctl workload create ./workload-spec.yaml
else
./rctl workload update ./workload-spec.yaml
fi
./rctl workload publish $WORKLOAD_NAME
workload_status="Not Ready"
workload_status_iterations=1
while [ "$workload_status" != "Ready" ];
do
 workload_status=`./rctl workload status $WORKLOAD_NAME -o json|jq .result[].status|tr -d '"'`
 echo $workload_status
 sleep 30
 if [ $workload_status_iterations -ge 30 ]; then
     break
 fi
 if [ "$workload_status" = "Failed" ]; then
     echo "Workload Deployment Failed"
     break
 fi
workload_status_iterations=$((workload_status_iterations+1))
done