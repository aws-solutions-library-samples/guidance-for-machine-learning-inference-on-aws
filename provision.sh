#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

print_help() {
	echo ""
	echo "Usage: $0 [runtime]"
	echo ""
	echo "   runtime - optional [docker|kubernetes}. Target runtime to provision."
        echo "             if not specified, reads value from ./config.properties"	
	echo ""
	echo "   When runtime is kubernetes, this script uses CloudFormation to create a management instance"
	echo "   which is used to launch and access an EKS cluster, and can be used to complete"
	echo "   the remaining steps in this project as well."
	echo ""
	echo "   When runtime is docker, this script does not provision any additional resources."
        echo ""	
}


runtime=$1
if [ "$runtime" == "" ]; then
	source ./config.properties
fi

if [ "$runtime" == "kubernetes" ]; then
	echo ""
	echo "Provisioning Management Instance and EKS cluster infrastructure ..."
	
	echo ""
	pushd ./0-provision
	./stack-create.sh
	popd
elif [ "$runtime" == "docker" ]; then
        echo ""
        echo "No additional infrastructure is required for runtime: $runtime..."
        echo ""       
else 
	print_help
fi
