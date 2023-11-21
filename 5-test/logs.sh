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
        CMD="docker logs -f ${test_image_name}-0"
    else
        if [ "$1" == "" ]; then
            CMD="docker ps -a | grep ${test_image_name}- | cut -d ' ' -f 1 | xargs -L 1 docker logs"
        else
            CMD="docker logs -f ${test_image_name}-$1"
        fi
    fi
    echo "$CMD"
    eval "$CMD"
elif [ "$runtime" == "kubernetes" ]; then
    if [ "$1" == "" ]; then
        kubectl -n ${test_namespace} get pods | grep ${test_image_name}- | cut -d ' ' -f 1 | xargs -L 1 kubectl -n ${test_namespace} logs 
    else
        kubectl -n ${test_namespace} logs -f $(kubectl -n ${test_namespace} get pods | grep ${test_image_name}-$1 | cut -d ' ' -f 1)
    fi
else
    echo "Runtime $runtime not recognized"
fi
