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
    CMD="docker ps -a | grep ${app_name}"
    if [ ! "$verbose" == "false" ]; then
        echo -e "\n${CMD}\n"
    fi
    eval "${CMD}"
elif [ "$runtime" == "kubernetes" ]; then
    if [ "$1" == "" ]; then
        CMD="kubectl -n ${namespace} get pods"
        if [ ! "$verbose" == "false" ]; then
            echo -e "\n${CMD}\n"
        fi
        echo ""
        echo "Pods:"
        eval "${CMD}"
        CMD="kubectl -n ${namespace} get services"
        if [ ! "$verbose" == "false" ]; then
            echo -e "\n${CMD}\n"
        fi
        echo ""
        echo "Services:"
        eval "${CMD}"
    else
        CMD="kubectl -n ${namespace} get pod $(kubectl -n ${namespace} get pods | grep ${app_name}-$1 | cut -d ' ' -f 1) -o wide"
        if [ ! "$verbose" == "false" ]; then
            echo -e "\n${CMD}\n"
        fi
        echo ""
        echo "Pod:"
        eval "${CMD}"
        CMD="kubectl -n ${namespace} get service ${app_name}-$1"
        if [ ! "$verbose" == "false" ]; then
            echo -e "\n${CMD}\n"
        fi
        echo ""
        echo "Service:"
        eval "${CMD}"
    fi
else
    echo "Runtime $runtime not recognized"
fi
