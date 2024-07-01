#!/bin/bash

source ../config.properties

CMD="aws cloudformation create-stack --stack-name ManagementInstance --template-body file://ManagementInstance.json --capabilities CAPABILITY_IAM"

if [ ! "$verbose" == "false" ]; then
        echo "\n${CMD}\n"
fi
eval "${CMD}"

