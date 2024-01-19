#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

print_help() {
	echo ""
	echo "Usage: $0 [runtime]"
	echo ""
	echo "   runtime - optional [docker|kubernetes}. Target runtime to destroy."
        echo "             if not specified, reads value from ./config.properties"	
	echo ""
	echo "   When runtime is kubernetes, this script uses CloudFormation to delete all stacks created by this project's provision script"
	echo ""
	echo "   When runtime is docker, this script does not remove any resources."
        echo ""	
}


runtime=$1
if [ "$runtime" == "" ]; then
	source ./config.properties
fi

if [ "$runtime" == "kubernetes" ]; then
	echo ""
	echo "Destroying project infrastructure ..."
	
	echo ""
	pushd ./6-destroy
	./cfn-delete.sh
	popd
elif [ "$runtime" == "docker" ]; then
        echo ""
        echo "No additional project asset cleanup is required for runtime: $runtime"
        echo ""       
else 
	print_help
fi
