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
while [ $server -lt $servers ]
do
	if [ "$runtime" == "docker" ]; then
		instance_ip=$(cat /etc/hosts | grep  ${app_name}-${server} | awk '{print $1}')
	elif [ "$runtime" == "kubernetes" ]; then
		instance_ip=$(host ${app_name}-${server}.${namespace}.svc.cluster.local | grep "has address" | cut -d ' ' -f 4)
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
		echo "Request: $request, Server: $server, IP: $endpoint_ip, Model: $model"
		./clock.sh curl http://${endpoint_ip}:8080/predictions/model$model
		model=$((model+1))
		request=$((request+1))
		sleep $request_frequency
	done
	model=0
	server=$((server+1))
done

rm -f  ./endpoint_ip.conf
