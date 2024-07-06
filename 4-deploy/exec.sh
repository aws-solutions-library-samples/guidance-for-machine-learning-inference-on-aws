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
    CMD="docker exec -it ${app_name}-0 bash"
    if [ ! "$verbose" == "false" ]; then
        echo -e "\n${CMD}\n"
    fi
    eval "${CMD}"
elif [ "$runtime" == "kubernetes" ]; then
    CMD="kubectl -n ${namespace} exec -it $(kubectl -n ${namespace} get pod | grep ${app_name}-$1 | cut -d ' ' -f 1) -- bash"
    if [ ! "$verbose" == "false" ]; then
        echo -e "\n${CMD}\n"
    fi
    eval "${CMD}"
else
    echo "Runtime $runtime not recognized"
fi
