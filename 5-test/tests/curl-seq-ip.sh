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
    echo "Configured number of model servers ($num_servers) from environment"
fi

server=0
servers=$num_servers
model=0
models=$num_models

# get server ip addresses
rm -f  ./endpoint_ip.conf
echo ""
echo "runtime=$runtime"
echo "Sending sequential requests to $servers servers with $models models each ..."
while [ $server -lt $servers ]
do
	if [ "$runtime" == "docker" ]; then
		instance_ip=$(cat /etc/hosts | grep  ${app_name}-${server} | awk '{print $1}')
	elif [ "$runtime" == "kubernetes" ]; then
		#echo "host=${app_name}-${server}.${namespace}.svc.cluster.local"
		instance_ip=$(host ${app_name}-${server}.${namespace}.svc.cluster.local | grep "has address" | cut -d ' ' -f 4)
		#echo "instance_ip=$instance_ip"
	fi
	echo $instance_ip >> endpoint_ip.conf
	server=$((server+1))
done

# call each model
server=0
request=0
echo "Endpoints:"
cat ./endpoint_ip.conf
for endpoint_ip in $(cat ./endpoint_ip.conf)
do
	while [ $model -lt $models ] 
	do
	    if [ "${model_server}" == "fastapi" ]; then
		    fastapi_model_name=model${model}
		    echo "Request: $request, Server: $server, IP: $endpoint_ip, Model: $fastapi_model_name"
		    ./clock.sh ./fastapi-infer.sh ${endpoint_ip} ${fastapi_model_name}
		elif [ "${model_server}" == "triton" ]; then
		    triton_model_name=${huggingface_model_name}-$((model+1))
		    echo "Request: $request, Server: $server, IP: $endpoint_ip, Model: $triton_model_name"
		    ./clock.sh ./triton-infer.sh ${endpoint_ip} ${triton_model_name}
		else
		    echo "Unrecognized model server: ${model_server}"
		fi
		model=$((model+1))
		request=$((request+1))
		sleep $request_frequency
	done
	model=0
	server=$((server+1))
done

rm -f  ./endpoint_ip.conf
