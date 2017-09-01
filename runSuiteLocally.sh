#!/bin/bash

ORG_DIR=`pwd`
TEMP_DIR=`mktemp -d` && cd $TEMP_DIR

echo "First start minikube..."
minikube start
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Starting minikube had an issue."
    echo
    exit 1
fi


echo "Create the Google Pub Sub Topics Locally"
# TODO
ls /thiswillfail
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to create the Google Pubsub topics failed."
    echo
    exit 1
fi


echo "Start Mongo DB"
# TODO
ls /thiswillfail
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to create the Mongo DB failed. Please check the output above."
    echo
    exit 1
fi


echo "Deploy locally to Kubernetes..."
git clone git@github.com:SudoStream/devops_k8s.git
cd devops_k8s
./deployServiceToKubernetes.sh "local"
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to create the Google Pubsub topics failed."
    echo
    exit 1
fi


### Cleanup
cd $ORG_DIR
rm -rf $TEMP_DIR
