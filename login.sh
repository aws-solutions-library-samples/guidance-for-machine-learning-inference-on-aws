#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

print_help() {
	echo ""
	echo "Usage: $0"
	echo ""
	echo "   This script assists with logging in to a private container registry."
	echo "   By default we use Amazon ECR, however the script can be extended to support other registries as needed."
	echo "   In order to login successfully, the environment in which this script is running, must be configured"
	echo "   with an IAM role allowing access to ECR in the target AWS account."
	echo ""
}

if [ "$1" == "" ]; then

	if [ -f ./config.properties ]; then
    		source ./config.properties
	elif [ -f ../config.properties ]; then
    		source ../config.properties
	else
    		echo "config.properties not found!"
	fi

	# Login to base container registry
	case "$registry_type" in
    		"ecr")
			echo ""
        		echo "Logging in to $registry_type $registry ..."
        		CMD="aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $registry"
        		if [ ! "$verbose" == "false" ]; then
                		echo -e "\n${CMD}\n"
        		fi
        		eval "${CMD}"
        		;;
    		*)
        		echo "Login for registry_type=$registry_type is not implemented"
        		;;
	esac

	if [ "$target_platform" == "nim" ]; then
		echo ""
		echo "Logging in to NIM registry $nim_registry ..."
		CMD="echo \"${nim_api_key}\" | docker login --username \\\$oauthtoken --password-stdin ${nim_registry}"
                #if [ ! "$verbose" == "false" ]; then
                	#echo -e "\n${CMD}\n"
                #fi
                eval "${CMD}"
	fi
else
	print_help
fi
