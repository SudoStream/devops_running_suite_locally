#!/usr/bin/env bash

function deployJob() {
   echo
   ./deployJobToKubernetes.sh --service="$1" --type="local"
    if [ $? -ne 0 ]; then
        echo
        echo "ERROR: Attempting to deploy $1 failed"
        echo
        cleanup
        exit 1
    fi
    echo "$1 deployed."
}

function deleteAllPodsToForceRedeploy() {
    echo "Deleting all pods to force redeploy"
    kubectl delete pod `kubectl  get pods | awk '{ print $1 }' | grep -v NAME`
}

function deployService() {
   echo
   ./deployServiceToKubernetes.sh --service="$1" --type="local"
    if [ $? -ne 0 ]; then
        echo
        echo "ERROR: Attempting to deploy $1 failed"
        echo
        cleanup
        exit 1
    fi
    echo "$1 deployed."
}


function cleanup {
    echo "Cleanup ..."

    #gcloud beta pubsub topics delete UI_REQUEST_TOPIC_LOCAL

    mongod_pid=`ps -ef | grep mongod | grep dbpath | grep timetoteach | grep -v grep | awk '{print $2}'`
    echo "killing mongo with pid = ${mongod_pid}"
    kill -9 ${mongod_pid}
    echo "mongo killed"

    kafka_server_pid=`ps -ef | grep -i kafka | grep zookeeper | grep 'config/server.properties' | awk ' { print $2}' `
    echo "kafka server with pid = ${kafka_server_pid}"
    kill -9 ${kafka_server_pid}
    echo "kafka server killed"

    zookeeper_pid=`ps -ef | grep -i kafka | grep zookeeper | grep 'config/zookeeper.properties' | awk ' { print $2}'`
    echo "zookeeper with pid = ${zookeeper_pid}"
    kill -9 ${zookeeper_pid}
    echo "zookeeper killed"

    echo "Stopping minikube"
    minikube stop
}

function buildAllModules {
    echo "build all mobules..."
    curr_dir=`pwd`

    eval $(minikube docker-env)

    cd /home/andy/projects/timeToTeach/lib_messages
    gcloud docker --authorize-only
    sbt publishLocal

    cd /home/andy/projects/timeToTeach/job_esandospopulator
    gcloud docker --authorize-only
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/job_test_populator
    gcloud docker --authorize-only
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_classtimetable-reader
    gcloud docker --authorize-only
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_classtimetable-writer
    gcloud docker --authorize-only
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_es-and-os-reader
    gcloud docker --authorize-only
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_school-reader
    gcloud docker --authorize-only
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_timetoteach-ui-server
    gcloud docker --authorize-only
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_user-reader
    gcloud docker --authorize-only
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_user-writer
    gcloud docker --authorize-only
    sbt docker:publishLocal

    cd $curr_dir
    echo "build all mobules...   DONE"
}
