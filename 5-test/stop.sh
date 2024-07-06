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
echo "Processor: $processor"

if [ "$runtime" == "docker" ]; then
    if [ "$1" == "" ]; then
    test_container=0
        while [ $test_container -lt $num_test_containers ]; do
            CMD="docker rm -f ${test_image_name}-${test_container}"
            if [ ! "$verbose" == "false" ]; then
                echo -e "\n${CMD}\n"
            fi
            eval "${CMD}"
            test_container=$((test_container+1))
        done
    else
        CMD="Docker rm -f ${test_image_name}-$1"
        echo "$CMD"
        eval "$CMD"
    fi
elif [ "$runtime" == "kubernetes" ]; then
    pushd ./5-test > /dev/null
    CMD="kubectl delete -f ${test_dir}"
    if [ ! "$verbose" == "false" ]; then
        echo -e "\n${CMD}\n"
    fi
    eval "${CMD}"
    popd > /dev/null
else
    echo "Runtime $runtime not recognized"
fi
