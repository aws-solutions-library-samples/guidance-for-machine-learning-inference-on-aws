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
    CMD="docker ps -a | grep ${test_image_name}-"
elif [ "$runtime" == "kubernetes" ]; then
    if [ "$1" == "" ]; then
        echo ""
        echo "Pods:"
        CMD="kubectl -n ${test_namespace} get pods"
    else
        echo ""
        echo "Pod:"
        CMD="kubectl -n ${test_namespace} get pod $(kubectl -n ${test_namespace} get pods | grep ${test_image_name}-$1 | cut -d ' ' -f 1) -o wide"
    fi
else
    echo "Runtime $runtime not recognized"
fi
if [ ! "$verbose" == "false" ]; then
    echo "\n${CMD}\n"
fi
eval "${CMD}"

