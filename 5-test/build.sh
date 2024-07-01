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

#use CMD variable for better debugging
CMD="docker build -t ${registry}${test_image_name}${test_image_tag} --build-arg BASE_IMAGE=${registry}${base_image_name}${base_image_tag} \
             -f 5-test/Dockerfile ."
if [ ! "$verbose" == "false" ]; then
    echo "\n${CMD}\n"
fi
eval "${CMD}"
    
