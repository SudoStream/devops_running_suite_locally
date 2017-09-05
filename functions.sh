#!/usr/bin/env bash

function cleanup {
    echo "Cleanup ..."

    gcloud beta pubsub topics delete UI_REQUEST_TOPIC_LOCAL

    mongod_pid=`ps -ef | grep mongod | grep dbpath | grep timetoteach | grep -v grep | awk '{print $2}'`
    kill -9 ${mongod_pid}

    minikube stop
}

