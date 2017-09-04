#!/bin/bash

function cleanup {
    echo "Cleanup ..."

    gcloud beta pubsub topics delete UI_REQUEST_TOPIC_LOCAL

    mongod_pid=`ps -ef | grep mongod | grep dbpath | grep timetoteach | grep -v grep | awk '{print $2}'`
    kill -9 ${mongod_pid}

    minikube stop
}


ORG_DIR=`pwd`
TEMP_DIR=`mktemp -d` && cd $TEMP_DIR

echo "First start minikube..."
minikube start
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Starting minikube had an issue."
    echo
    cleanup
    exit 1
fi


echo "Create the Google Pub Sub Topics 'Locally' ( Cough )"
gcloud beta pubsub topics create UI_REQUEST_TOPIC_LOCAL
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to create the Google Pubsub topics failed."
    echo
    cleanup
    exit 1
fi


echo "Start Mongo DB"
nohup mongod --dbpath /data/mongodb/timetoteach &
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to create the Mongo DB failed. Please check the output above."
    echo
    cleanup
    exit 1
fi


echo "Deploy locally to Kubernetes..."
git clone git@github.com:SudoStream/devops_k8s.git
cd devops_k8s
./deployServiceToKubernetes.sh --service="timetoteach-ui-server" --type="local"
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to create the Google Pubsub topics failed."
    echo
    cleanup
    exit 1
fi


### Cleanup
cd $ORG_DIR
rm -rf $TEMP_DIR

