#!/bin/bash

# Example bash based automation script that can be included in an 
# external automation pipeline to check the status and progress 
# of provisioning and readiness of an Upstream Kubernetes cluster
# in vSphere Environments 

# For cluster provisioning, use the "rctl apply -f cluster-spec.yaml"
# command. Provisioning can take several minutes. You can use this 
# example script to check progress and status. 

# Assumptions
# This script assumes the following
# 1. The RCTL CLI is installed and configured to point to the project
# where the cluster is being provisioned 
# 2. The JQ CLI is configured and installed 

# Provide the name of your cluster 
name=vmware-prod-oct
echo -e "status of cluster............ ${name}"
active_status_counter=1
ClusterActiveStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterActive"))[0].status' |tr -d '"'`
echo $ClusterActiveStatus
while [ $ClusterActiveStatus != "Success" ]
do
  if [ $active_status_counter -ge 60 ];
  then
    break
  fi
  active_status_counter=$((active_status_counter+1))
  ClusterActiveStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterActive"))[0].status' | tr -d '"'`
  if [ $ClusterActiveStatus == "Failed" ];
  then
    echo -e " Cluster Status Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi
  ClusterInitializedStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterInitialized"))[0].status' | tr -d '"'`

  if [ $ClusterInitializedStatus == "Failed" ];
  then
    echo -e " ClusterInitializedStatus Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi
  ClusterBootstrapNodeInitializedStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterBootstrapNodeInitialized"))[0].status' |tr -d '"'`

  if [ $ClusterBootstrapNodeInitializedStatus == "Failed" ];
  then
    echo -e " ClusterBootstrapNodeInitializedStatus Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi
  ClusterProviderInfraInitializedStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterProviderInfraInitialized"))[0].status'|tr -d '"'`
  if [ $ClusterProviderInfraInitializedStatus == "Failed" ];
  then
    echo -e " ClusterProviderInfraInitializedStatus Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi
  ClusterSpecAppliedStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterSpecApplied"))[0].status'|tr -d '"'`
  sleep 10
  if [ $ClusterSpecAppliedStatus == "Failed" ];
  then
    echo -e " ClusterSpecAppliedStatus Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi
  ClusterControlPlaneReadyStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterControlPlaneReady"))[0].status'|tr -d '"'`
  sleep 10
  if [ $ClusterControlPlaneReadyStatus == "Failed" ];
  then
    echo -e " ClusterControlPlaneReadyStatus Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi
  ClusterHealthyStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterHealthy"))[0].status'|tr -d '"'`
  sleep 10
  if [ $ClusterHealthyStatus == "Failed" ];
  then
    echo -e " ClusterHealthyStatus Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi
  ClusterPivotedStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterPivoted"))[0].status'|tr -d '"'`
  sleep 10
  if [ $ClusterPivotedStatus == "Failed" ];
  then
    echo -e " ClusterPivotedStatus Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi

  ClusterBootstrapNodeDeletedStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterBootstrapNodeDeleted"))[0].status'|tr -d '"'`
  sleep 10
  if [ $ClusterBootstrapNodeDeletedStatus == "Failed" ];
  then
    echo -e " ClusterBootstrapNodeDeletedStatus Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi
  ClusterActiveStatus=`./rctl get cluster ${name} -o json | jq '.status | select(.conditions != null) | .conditions | map(select(.type == "ClusterActive"))[0].status'|tr -d '"'`
  sleep 10
  if [ $ClusterActiveStatus == "Failed" ];
  then
    echo -e " ClusterBootstrapNodeDeletedStatus Did not Converge !! Failed "
    echo -e " Exit " && exit -1
  fi
done
if [ $ClusterActiveStatus == "Success" ];
then
    echo -e "[+] Cluster  Successfully Provisioned"
fi


if [ $ClusterActiveStatus != "Success" ];
then
    echo -e "[+] Cluster  Provisioned Failed" 
fi



