#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

# Pull base image from container registry

if [ -f ./config.properties ]; then
    source ./config.properties
elif [ -f ../config.properties ]; then
    source ../config.properties
else
    echo "config.properties not found!"
fi

CMD="docker pull ${registry}${base_image_name}${base_image_tag}"
if [ ! "$verbose" == "false" ]; then
        echo "\n${CMD}\n"
fi
eval "${CMD}"

