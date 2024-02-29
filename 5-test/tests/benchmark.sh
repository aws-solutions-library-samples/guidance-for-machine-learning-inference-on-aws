#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

if [ "$num_servers" == "" ]; then

    echo "Configuring number of model servers from config.properties ..."

    if [ -f ../config.properties ]; then
        source ../config.properties
    elif [ -f ../../config.properties ]; then
        source ../../config.properties
    elif [ -f ./config.properties ]; then
        source ./config.properties
    else
        echo "config.properties not found!"
    fi
else
    echo "Number of model servers ($num_servers) configured from environment ..."
fi

if [ "$runtime" == "docker" ]; then
    if [ "$model_server" == "fastapi" ]; then
        python benchmark_client.py --model_server fastapi --num_thread 2 --url http://${app_name}-[INSTANCE_IDX]:8080/predictions/model[MODEL_IDX] --is_multi_instance --n_instance ${num_servers} --is_multi_model_per_instance --n_model_per_instance ${num_models} --latency_window_size 1000 --cache_dns 
    elif [ "${model_server}" == "triton" ]; then
	    python benchmark_client.py --model_server triton --post --num_thread 2 --url http://${app_name}-[INSTANCE_IDX]:8000/v2/models/${huggingface_model_name}-[MODEL_IDX]/infer --is_multi_instance --n_instance ${num_servers} --is_multi_model_per_instance --n_model_per_instance ${num_models} --latency_window_size 1000 --cache_dns
    else
	echo "Unrecognized model server: ${model_server}"
    fi
elif [ "$runtime" == "kubernetes" ]; then 
    python benchmark_client.py --num_thread 2 --url http://${app_name}-[INSTANCE_IDX].${namespace}.svc.cluster.local:8080/predictions/model[MODEL_IDX] --is_multi_instance --n_instance ${num_servers} --is_multi_model_per_instance --n_model_per_instance ${num_models} --latency_window_size 1000 --cache_dns 
else
    echo "Runtime $runtime not recognized"
fi
