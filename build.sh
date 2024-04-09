#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

BASE_IMAGE=python:3.9
MODEL_SERVER=fastapi

print_help() {
	echo ""
	echo "Usage: $0 [arg]"
	echo ""
	echo "   When no arguments are specified, this script builds a base container "
	echo "   for the processor type, configured in config.properties."
	echo "   Optionally, the script can push/pull the base image to/from a container registry."
	echo ""
	echo "   Available optional arguments:"
	echo "      push   - push base image to container registry"
	echo "      pull   - pull base image from container registry"
        echo ""	
}


action=$1
if [ "$action" == "" ]; then
	source ./config.properties

	if [ "$model_server" == "torchserve" ]
	then
  	BASE_IMAGE=pytorch/torchserve:latest-${processor}
	MODEL_SERVER=torchserve
	fi

	echo ""
	echo "Building base container ... "
	
	echo ""
	dockerfile=./1-build/Dockerfile-base-${processor}
	if [ -f $dockerfile ]; then
		echo "    ... base-${processor} ... "
		docker build --build-arg BASE_IMAGE="${BASE_IMAGE}" --build-arg MODEL_SERVER="${MODEL_SERVER}" -t ${registry}${base_image_name}${base_image_tag} -f $dockerfile .
	else
		echo "Dockerfile $dockerfile was not found."
	        echo "Please ensure that processor is configured with a supported value in config.properties"
		exit 1
	fi
elif [ "$action" == "push" ]; then
	./1-build/push.sh
elif [ "$action" == "pull" ]; then
	./-build/pull.sh
else 
	print_help
fi
