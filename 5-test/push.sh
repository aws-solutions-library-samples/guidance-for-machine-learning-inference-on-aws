#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

# Push model image to container registry

if [ -f ./config.properties ]; then
    source ./config.properties
elif [ -f ../config.properties ]; then
    source ../config.properties
else
    echo "config.properties not found!"
fi

./login.sh
# Create registry if needed
IMAGE=${test_image_name}
REGISTRY_COUNT=$(aws ecr describe-repositories | grep ${IMAGE} | wc -l)
if [ "$REGISTRY_COUNT" == "0" ]; then
    CMD="aws ecr create-repository --repository-name ${IMAGE} --region ${region}"
    if [ ! "$verbose" == "false" ]; then
        echo -e "\n${CMD}\n"
    fi
    eval "${CMD}"
fi

CMD="docker push ${registry}${test_image_name}${test_image_tag}"
if [ ! "$verbose" == "false" ]; then
    echo -e "\n${CMD}\n"
fi
eval "${CMD}"

