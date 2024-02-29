#!/bin/bash

endpoint_ip=$1
if [ "$endpoint_ip" == "" ]; then
	endpoint_ip=localhost
fi

triton_model_name=$2
if [ "$triton_model_name" == "" ]; then
	triton_model_name=bert-base-multilingual-cased-1
fi

triton_server_port=$3
if [ "$triton_server_port" == "" ]; then
	triton_server_port=8000
fi

#curl --location --request POST "http://${endpoint_ip}:8000/v2/models/${triton_model_name}/infer" --header 'Content-Type: application/json' --data-raw '{"inputs":[{"name":"seq_0","shape":[1,1],"datatype":"BYTES","data":[""]},{"name":"seq_1","shape":[1,1],"datatype":"BYTES","data":[""]}]}'

curl --location --request POST "http://${endpoint_ip}:${triton_server_port}/v2/models/${triton_model_name}/infer" --header 'Content-Type: application/json' --data-raw '{"inputs":[{"name":"seq_0","shape":[1,1],"datatype":"BYTES","data":["What does the little engine say"]},{"name":"seq_1","shape":[1,1],"datatype":"BYTES","data":["In the childrens story about the little engine a small locomotive is pulling a large load up a mountain. Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: \"I think I can\" as it is pulling the heavy load all the way to the top of the mountain. On the way down it says: \"I thought I could\"."]}]}'

#MODEL_NAME=bert-base-multilingual-cased
#for i in $(seq 2); do
#	TRITON_MODEL_NAME=${MODEL_NAME}-${i}
#	echo ""
#	curl --location --request POST "http://localhost:8000/v2/models/${TRITON_MODEL_NAME}/infer" --header 'Content-Type: application/json' --data-raw '{"inputs":[{"name":"seq_0","shape":[1,1],"datatype":"BYTES","data":["What does the little engine say"]},{"name":"seq_1","shape":[1,1],"datatype":"BYTES","data":["In the childrens story about the little engine a small locomotive is pulling a large load up a mountain. Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: \"I think I can\" as it is pulling the heavy load all the way to the top of the mountain. On the way down it says: \"I thought I could\"."]}]}'
#done

