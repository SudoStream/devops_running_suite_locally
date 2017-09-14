#!/bin/bash

source ./functions.sh

ORG_DIR=`pwd`
TEMP_DIR=`mktemp -d` && cd $TEMP_DIR

echo "First start minikube..."
minikube start --insecure-registry 10.0.0.0/24 --memory 8192
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Starting minikube had an issue."
    echo
    cleanup
    exit 1
fi

eval $(minikube docker-env)

echo "Start Kafka's Zookeeper..."
nohup ${HOME}/localApps/kafka/current/bin/zookeeper-server-start.sh ${HOME}/localApps/kafka/current/config/zookeeper.properties >/home/andy/projects/timeToTeach/kafka-zookeeper.log 2>&1  &
sleep 5

echo "Start Kafka Server..."
nohup ${HOME}/localApps/kafka/current/bin/kafka-server-start.sh ${HOME}/localApps/kafka/current/config/server.properties >/home/andy/projects/timeToTeach/kafka-server.log 2>&1  &
sleep 10

echo "Add topics..."
${HOME}/localApps/kafka/current/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic EXPERIENCES_AND_OUTCOMES
${HOME}/localApps/kafka/current/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic UI_REQUEST
${HOME}/localApps/kafka/current/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic SYSTEM_ALL_EVENTS_LOG
echo " ... topics added"

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

./generalSetup.sh
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Running general setup failed."
    echo
    cleanup
    exit 1
fi


./deployServiceToKubernetes.sh --service="timetoteach-ui-server" --type="local"
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to deploy timetoteach-ui-server failed."
    echo
    cleanup
    exit 1
fi
echo "timetoteach-ui-server deployed."

./deployJobToKubernetes.sh --service=esandospopulator --type=local
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to deploy esandospopulator failed"
    echo
    cleanup
    exit 1
fi
echo "esandospopulator deployed."

./deployServiceToKubernetes.sh --service="es-and-os-reader" --type="local"
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: Attempting to deploy es-and-os-reader failed."
    echo
    cleanup
    exit 1
fi
echo "es-and-os-reader deployed."



### Cleanup
cd $ORG_DIR
rm -rf $TEMP_DIR

