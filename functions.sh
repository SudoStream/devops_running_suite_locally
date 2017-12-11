#!/usr/bin/env bash

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
    sbt publishLocal

    cd /home/andy/projects/timeToTeach/job_esandospopulator
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/job_test_populator
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_classtimetable-reader
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_classtimetable-writer
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_es-and-os-reader
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_school-reader
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_timetoteach-ui-server
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_user-reader
    sbt docker:publishLocal

    cd /home/andy/projects/timeToTeach/svc_user-writer
    sbt docker:publishLocal

    cd $curr_dir
    echo "build all mobules...   DONE"
}
