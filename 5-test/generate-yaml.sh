#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

set -a

if [ -f ../config.properties ]; then
    source ../config.properties
elif [ -f ./config.properties ]; then
    source ./config.properties
else
    echo "config.properties not found!"
fi

prefix=${test_image_name}-
instance_start=0
instances=${num_test_containers}

if [ -d ./${test_dir} ]; then
    rm -rf ./${test_dir}
fi
mkdir -p ./${test_dir}

if [ -f ./cmd_pod.properties ]; then
	source ./cmd_pod.properties
	rm -f ./cmd_pod.properties
fi
echo "cmd_pod=$cmd_pod"
echo "template=$template"

instance=$instance_start
while [ $instance -lt $instances ]
do
	export instance_name=${prefix}${instance}
	echo "Generating ./${test_dir}/${instance_name}.yaml ..."
	CMD="cat $template | envsubst > ./${test_dir}/${instance_name}.yaml"
        if [ ! "$verbose" == "false" ]; then
            echo "\n${CMD}\n"
        fi
        eval "${CMD}"
	instance=$((instance+1))
done

set +a
