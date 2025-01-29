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
echo "Platform: $target_platform"
echo "Runtime: $runtime"
echo "Processor: $processor"

if [ "$runtime" == "docker" ]; then
    server=0
    while [ $server -lt $num_servers ]; do
	    run_opts="--name ${app_name}-${server} -e NUM_MODELS=$num_models -e POSTPROCESS=$postprocess -e QUIET=$quiet -P -v $(pwd)/../3-pack:/app/dev"    
    	if [ "$processor" == "gpu" ]; then
            run_opts="--gpus 1 ${run_opts}"
    	fi
	if [ "$processor" == "inf" ]; then
	    run_opts="--device=/dev/neuron${server} ${run_opts}"
	fi
	image_uri=${registry}${model_image_name}${model_image_tag}
	if [ "$target_platform" == "nim" ]; then
		image_uri=${nim_registry}${model_image_name}${model_image_tag}
	fi
    	CMD="docker run -d ${run_opts} ${image_uri}"
        if [ ! "$verbose" == "false" ]; then
            echo -e "\n${CMD}\n"
        fi
        eval "${CMD}"
	server=$((server+1))
    done
elif [ "$runtime" == "kubernetes" ]; then
    kubectl create namespace ${namespace} --dry-run=client -o yaml | kubectl apply -f -
    if [ "$target_platform" == "nim" ]; then
	echo ""
	echo "Creating nim image pull secret  ..."
	kubectl -n ${namespace} create secret docker-registry nvcrimagepullsecret --docker-server=${nim_registry} --docker-username=\$oauthtoken --docker-password=${nim_api_key} --docker-email=email@domain.ext
    fi
    ./generate-yaml.sh
    CMD="kubectl apply -f ${app_dir}"
    if [ ! "$verbose" == "false" ]; then
        echo -e "\n${CMD}\n"
    fi
    eval "${CMD}"
else
    echo "Runtime $runtime not recognized"
fi
