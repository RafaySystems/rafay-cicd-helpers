#! /bin/bash
curl -s -o rctl-linux-amd64.tar.bz2  https://s3-us-west-2.amazonaws.com/rafay-prod-cli/publish/rctl-linux-amd64.tar.bz2
tar -xf rctl-linux-amd64.tar.bz2
chmod 0755 rctl
CLUSTER_NAME=$1
PROJECT_NAME=$2
./rctl config set project $PROJECT_NAME
./rctl get cluster $CLUSTER_NAME -p $PROJECT_NAME > /dev/null 2>&1
if [ $? -eq 0 ];
then
	echo "[+]  ${CLUSTER_NAME} cluster exists.. deleting now"
	./rctl delete cluster $CLUSTER_NAME -p $PROJECT_NAME -y
	sleep 60
  CLUSTER_STATUS_ITERATIONS=1
  PROVISION_STATUS=`./rctl get cluster ${CLUSTER_NAME} -o json |jq '.provision.status' |cut -d'"' -f2`
  while [ "$PROVISION_STATUS" == "INFRA_DELETION_INPROGRESS" ]
  do
    sleep 60
    if [ $CLUSTER_STATUS_ITERATIONS -ge 30 ];
    then
      break
    fi
    CLUSTER_STATUS_ITERATIONS=$((CLUSTER_STATUS_ITERATIONS+1))
    ./rctl get cluster $CLUSTER_NAME -p $PROJECT_NAME > /dev/null 2>&1
    if [ $? -eq 0 ];
    then
	      PROVISION_STATUS=`./rctl get cluster ${CLUSTER_NAME} -o json |jq '.provision.status' |cut -d'"' -f2`
	  else
	    break
	  fi
    if [ $PROVISION_STATUS == "INFRA_DELETION_FAILED" ];
    then
      echo -e " !! Cluster Deletion failed !!  "
      echo -e " !! Exiting !!  " && exit -1
    fi
  done
fi
