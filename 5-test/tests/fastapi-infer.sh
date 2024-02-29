#!/bin/bash

endpoint_ip=$1
if [ "$endpoint_ip" == "" ]; then
	endpoint_ip=localhost
fi

fastapi_model_name=$2
if [ "$fastapi_model_name" == "" ]; then
	fastapi_model_name=model0
fi

curl --location --request GET "http://${endpoint_ip}:8080/predictions/${fastapi_model_name}"

#curl --location --request POST "http://${endpoint_ip}:8080/predictions/${fastapi_model_name}" --header 'Content-Type: application/json' --data-raw '{"inputs":[{"name":"seq_0","shape":[1,1],"datatype":"BYTES","data":["What does the little engine say"]},{"name":"seq_1","shape":[1,1],"datatype":"BYTES","data":["In the childrens story about the little engine a small locomotive is pulling a large load up a mountain. Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: \"I think I can\" as it is pulling the heavy load all the way to the top of the mountain. On the way down it says: \"I thought I could\"."]}]}'

