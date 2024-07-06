#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

if [ -f ../config.properties ]; then
    source ../config.properties
elif [ -f ./config.properties ]; then
    source ./config.properties
else
    echo "config.properties not found!"
fi

echo ""
echo "Runtime: $runtime"
echo ""

if [ "$runtime" == "docker" ]; then
    if [ "$1" == "bma" ]; then
        pushd ./5-test > /dev/null
        CMD="docker ps -a | grep ${test_image_name}- | cut -d ' ' -f 1 | xargs -L 1 docker logs | grep { | grep -v 0.0, | tee ./bmk-all.log"
        command -v bc > /dev/null
        if [ "$?" == "1" ]; then
            echo "bc not found"
            echo "Please 'sudo apt-get install -y bc' or 'sudo yum install -y bc', then try again"
        else
            if [ ! "$verbose" == "false" ]; then
                echo -e "\n${CMD}\n"
            fi
            eval "${CMD}"
            ./aggregate.sh ./bmk-all.log
        fi
        rm -f ./bmk-all.log
        popd > /dev/null
    else
        server=0
        run_links=""
        while [ $server -lt $num_servers ]; do
            run_links="${run_links} --link ${app_name}-${server}:${app_name}-${server}"
            server=$((server+1))
        done
        test_container=0
        while [ $test_container -lt $num_test_containers ]; do
            run_opts="--name ${test_image_name}-${test_container} ${run_links}"
            CMD="docker run -d ${run_opts} ${registry}${test_image_name}${test_image_tag}"
            if [ "$1" == "seq" ]; then
                CMD="$CMD bash -c 'pushd /app/tests && ./curl-seq-ip.sh'"
            elif [ "$1" == "rnd" ]; then
                CMD="$CMD bash -c 'pushd /app/tests && ./curl-rnd-ip.sh'"
            elif [ "$1" == "bmk" ]; then
                CMD="$CMD bash -c 'pushd /app/tests && ./benchmark.sh'"
            fi
            if [ ! "$verbose" == "false" ]; then
                echo -e "\n${CMD}\n"
            fi
            eval "${CMD}"
            test_container=$((test_container+1))
        done
    fi
elif [ "$runtime" == "kubernetes" ]; then
    pushd ./5-test > /dev/null
    if [ "$1" == "bma" ]; then
        CMD="kubectl -n ${test_namespace} get pods | grep ${test_image_name}- | cut -d ' ' -f 1 | xargs -L 1 kubectl -n ${test_namespace} logs | grep { | grep -v 0.0, | tee ./bmk-all.log"
        command -v bc > /dev/null
        if [ "$?" == "1" ]; then
            echo "bc not found"
            echo "Please 'sudo apt-get install -y bc' or 'sudo yum install -y bc', then try again"
        else
            if [ ! "$verbose" == "false" ]; then
                echo -e "\n${CMD}\n"
            fi
            eval "${CMD}"
            ./aggregate.sh ./bmk-all.log
        fi
        rm -f ./bmk-all.log
    else
        CMD="kubectl create namespace ${test_namespace} --dry-run=client -o yaml | kubectl apply -f -"
        if [ ! "$verbose" == "false" ]; then
            echo -e "\n${CMD}\n"
        fi
        eval "${CMD}"
        cmd_pod="while true; do date; sleep 10; done"
        template="./deployment-yaml.template"
        if [ "$1" == "seq" ]; then
            cmd_pod="pushd /app/tests && ./curl-seq-ip.sh"
            template="./job-yaml.template"
        elif [ "$1" == "rnd" ]; then
            cmd_pod="pushd /app/tests && ./curl-rnd-ip.sh"
            template="./job-yaml.template"
        elif [ "$1" == "bmk" ]; then
            cmd_pod="pushd /app/tests && ./benchmark.sh"
            template="./job-yaml.template"
         fi
        echo "export cmd_pod=\"$cmd_pod\"" > cmd_pod.properties
        echo "export template=$template" >> cmd_pod.properties
        eval "./generate-yaml.sh"
        CMD="kubectl apply -f ${test_dir}"
        if [ ! "$verbose" == "false" ]; then
            echo -e "\n${CMD}\n"
        fi
        eval "${CMD}"
    fi
    popd > /dev/null
else
    echo "Runtime $runtime not recognized"
fi
