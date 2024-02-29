#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

print_help() {
    echo ""
    echo "Usage: $0 [arg]"
    echo ""
    echo "   This script builds a model container using the traced/compiled model file and a model server."
    echo "   By default we use FastAPI and hypercorn to serve models, but the same approach can be extended"
    echo "   to other servers if needed. Optionally, this script can push/pull the model container"
    echo "   to/from a container registry."
    echo ""
    echo "   Available optional arguments:"
    echo "      push   - push model container to a registry"
    echo "      pull   - pull model container from a registry"
    echo ""
}

source ./config.properties

action=$1

if [ "$action" == "" ]; then
    model_file_name=${huggingface_model_name}_bs${batch_size}_seq${sequence_length}_pc${pipeline_cores}_${processor}.pt

    BASE_MODEL_SERVER_IMAGE=${registry}${base_image_name}${base_image_tag}
    if [ "${model_server}" == "triton" ]; then
	    BASE_MODEL_SERVER_IMAGE=$base_image_triton
    elif [ "${model_server}" == "torchserve" ]; then
	    BASE_MODEL_SERVER_IMAGE=$base_image_torchserve
    fi
    
    CMD="docker build -t ${registry}${model_image_name}${model_image_tag} --build-arg BASE_IMAGE=${BASE_MODEL_SERVER_IMAGE} \
                 --build-arg MODEL_NAME=${huggingface_model_name} --build-arg MODEL_FILE_NAME=${model_file_name} --build-arg PROCESSOR=${processor} \
                 --build-arg NUM_MODELS=${num_models} -f 3-pack/Dockerfile-${model_server} ."

    if [ "$VERBOSE" == "true" ]; then
	    echo ""
	    echo "$CMD"
	    echo ""
    fi

    eval "$CMD"

elif [ "$action" == "push" ]; then
    ./3-pack/push.sh
elif [ "$action" == "pull" ]; then
    ./3-pack/pull.sh
else
    print_help
fi
