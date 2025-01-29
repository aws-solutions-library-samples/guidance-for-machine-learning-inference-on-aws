#!/bin/bash

endpoint_ip=$1
if [ "$endpoint_ip" == "" ]; then
	endpoint_ip=localhost
fi

nim_model_name=$2
if [ "$nim_model_name" == "" ]; then
	nim_model_name=llama3-8b-instruct
fi

nim_server_port=$3
if [ "$nim_server_port" == "" ]; then
	nim_server_port=8000
fi

echo curl --location --request POST "http://${endpoint_ip}:${nim_server_port}/v1/chat/completions" --header 'accept: application/json' --header 'Content-Type: application/json' --data-raw '{"messages": [ { "content": "You provide simple answers to questions about childrens books", "role": "system" }, { "content": "What does the little engine say?", "role": "user" } ], "model": "meta/llama3-8b-instruct", "max_tokens": 16, "top_p": 1, "n": 1, "stream": false, "stop": "\n", "frequency_penalty": 0.0 }'

curl --location --request POST "http://${endpoint_ip}:${nim_server_port}/v1/chat/completions" --header 'accept: application/json' --header 'Content-Type: application/json' --data-raw '{"messages": [ { "content": "You provide simple answers to questions about childrens books", "role": "system" }, { "content": "What does the little engine say?", "role": "user" } ], "model": "meta/llama3-8b-instruct", "max_tokens": 16, "top_p": 1, "n": 1, "stream": false, "stop": "\n", "frequency_penalty": 0.0 }'



