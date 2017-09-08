#!/bin/bash

source ./functions.sh

ORG_DIR=`pwd`
TEMP_DIR=`mktemp -d` && cd $TEMP_DIR

echo "First start minikube..."
minikube start --insecure-registry 10.0.0.0/24
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Starting minikube had an issue."
    echo
    cleanup
    exit 1
fi

eval $(minikube docker-env)

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
nohup mongod --dbpath /data/mongodb/timetoteach --sslMode requireSSL --sslPEMKeyFile /etc/ssl/mongodb.pem --sslAllowInvalidCertificates  >/home/andy/projects/timeToTeach/mongod.log 2>&1  &
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
    echo "ERROR: Attempting to deploy timetoteach-ui-server failed."
    echo
    cleanup
    exit 1
fi

./deployJobToKubernetes.sh --service=esandospopulator --type=local
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to deploy esandospopulator failed"
    echo
    cleanup
    exit 1
fi



### Cleanup
cd $ORG_DIR
rm -rf $TEMP_DIR

