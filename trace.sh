#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

print_help() {
	echo ""
	echo "Usage: $0 "
	echo ""
	echo "   This script compiles/traces the model configured in config.properties and saves it locally as a .pt file"
	echo "   Tracing is supported on CPU, GPU, or Inferentia, however it must be done on a machine that has"
	echo "   the target processor chip available. Example: tracing a model for Inferentia must be done on an inf1 instance."
	echo ""
}


if [ "$1" == "" ]; then 
	source ./config.properties
	echo ""
	echo "Tracing model: $huggingface_model_name ..."
	
	dockerfile=./1-build/Dockerfile-base-${processor}
	echo ""
	if [ -f $dockerfile ]; then
		echo "   ... for processor: $processor ..."
		trace_opts=trace_opts_${processor}
		docker run ${!trace_opts} -it --rm -v $(pwd)/2-trace:/app/trace -v $(pwd)/config.properties:/app/config.properties ${registry}${base_image_name}${base_image_tag} bash -c "cd /app/trace; python model-tracer.py"
	else
		echo "Processor $processor is not supported. Please ensure the processor setting in config.properties is configured properly"
		exit 1
	fi
else
	print_help
fi

