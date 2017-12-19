#!/bin/bash

startFlavourCommand=$1
if [[ ${startFlavourCommand} == "all" ]]; then
    START_FLAVOUR="ALL"
elif [[ ${startFlavourCommand} == "kafka-mongo" ]]; then
    START_FLAVOUR="KAFMON"
else
    echo
    echo "ERROR: Invalid start flavour. Should be... "
    echo
    echo "  $0 [all|kafka-mongo]"
    echo
    exit 1
fi

ORG_DIR=`pwd`
TEMP_DIR=`mktemp -d` && cd $TEMP_DIR

echo "Start flavour = '${START_FLAVOUR}'"

if [[ "${START_FLAVOUR}" == "ALL" ]]; then
    source ${ORG_DIR}/functions.sh
    echo "First start minikube..."
    #minikube start --insecure-registry 10.0.0.0/24 --memory 5000 --cpus 3
    minikube start --memory 10000 --cpus 3
    if [ $? -ne 0 ]; then
        echo
        echo "ERROR: Starting minikube had an issue."
        echo
        cleanup
        exit 1
    fi
  # minikube addons enable registry-creds
#    docker login -u oauth2accesstoken -p "$(gcloud auth print-access-token)" https://eu.gcr.io
    gcloud docker --authorize-only
#   eval $(minikube docker-env)
    buildAllModules
fi


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
sleep 15

if [[ "${START_FLAVOUR}" == "ALL" ]]; then
    echo "Deploy locally to Kubernetes..."
    git clone git@github.com:SudoStream/devops_k8s.git
    cd devops_k8s

    ./setupKubernetesSecrets.sh --type="local"
    if [ $? -ne 0 ]; then
        echo
        echo "ERROR: Running general setup failed."
        echo
        cleanup
        exit 1
    fi

    deployJob "esandospopulator"
    deployJob "test-populator"
    deployService "es-and-os-reader"
    deployService "classtimetable-writer"
    deployService "classtimetable-reader"
    deployService "school-reader"
    deployService "user-reader"
    deployService "user-writer"
    deployService "timetoteach-ui-server"
fi


### Cleanup
cd $ORG_DIR
rm -rf $TEMP_DIR

