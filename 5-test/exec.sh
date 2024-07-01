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
    if [ "$num_test_containers" == "1" ]; then
        CMD="docker exec -it ${test_image_name}-0 bash"
    else
        if [ "$1" == "" ]; then
            echo "Please specify test container index to exec into. Defaulting to 0"
            CMD="docker exec -it ${test_image_name}-0 bash"
        else
            CMD="docker exec -it ${test_image_name}-$1 bash"
        fi
    fi
elif [ "$runtime" == "kubernetes" ]; then
    if [ "$num_test_containers" == "1" ]; then
        CMD="kubectl -n ${test_namespace} exec -it $(kubectl -n ${test_namespace} get pod | grep ${test_image_name}-0 | cut -d ' ' -f 1) -- bash"
    else
        if [ "$1" == "" ]; then
            echo "Please specify test container index to exec into. Defaulting to 0."
            CMD="kubectl -n ${test_namespace} exec -it $(kubectl -n ${test_namespace} get pod | grep ${test_image_name}-0 | cut -d ' ' -f 1) -- bash"
        else
            CMD="kubectl -n ${test_namespace} exec -it $(kubectl -n ${test_namespace} get pod | grep ${test_image_name}-$1 | cut -d ' ' -f 1) -- bash"
        fi
    fi
else
    echo "Runtime $runtime not recognized"
fi
if [ ! "$verbose" == "false" ]; then
    echo "\n${CMD}\n"
fi
eval "${CMD}"

