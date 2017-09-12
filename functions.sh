#!/usr/bin/env bash

function cleanup {
    echo "Cleanup ..."

    #gcloud beta pubsub topics delete UI_REQUEST_TOPIC_LOCAL

    mongod_pid=`ps -ef | grep mongod | grep dbpath | grep timetoteach | grep -v grep | awk '{print $2}'`
    kill -9 ${mongod_pid}

    kafka_server_pid=`ps -ef | grep -i kafka | grep zookeeper | grep 'config/server.properties' | awk ' { print $2}' `
    kill -9 ${kafka_server_pid}

    zookeeper_pid=`ps -ef | grep -i kafka | grep zookeeper | grep 'config/zookeeper.properties' | awk ' { print $2}'`
    kill -9 ${zookeeper_pid}

    minikube stop
}

