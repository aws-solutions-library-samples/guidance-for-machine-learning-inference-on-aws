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
IMAGE=${model_image_name}
REGISTRY_COUNT=$(aws ecr describe-repositories | grep ${IMAGE} | wc -l)
if [ "$REGISTRY_COUNT" == "0" ]; then
    aws ecr create-repository --repository-name ${IMAGE} --region ${region}
fi

docker push ${registry}${model_image_name}${model_image_tag}
