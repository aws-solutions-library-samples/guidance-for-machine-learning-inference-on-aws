#!/bin/bash

help () {
	echo ""
	echo "Usage: "
	echo "   $0 <ACTION> <ENTITY> <PROCESSOR>"
	echo ""
	echo "   ACTION    - start, describe, status, stop"
	echo "   ENTITY    - model or test"
	echo "   PROCESSOR - cpu, gpu, graviton, inf"
	echo ""
}

if [ "$3" == "" ]; then
	help
else
	source .env
	export ACTION=$1
	export ENTITY=$2
	export ENTITY_UPPER=$(echo $ENTITY | tr '[:lower:]' '[:upper:]')
	export PROCESSOR=$3
	export PROCESSOR_UPPER=$(echo $PROCESSOR | tr '[:lower:]' '[:upper:]')
	export VAR_NAME_INSTANCE_TYPE=INSTANCE_TYPE_${PROCESSOR_UPPER}
	export INSTANCE_TYPE=$(printenv $VAR_NAME_INSTANCE_TYPE)
	export VAR_IMAGE_NAME=${ENTITY_UPPER}_IMAGE_NAME
	export IMAGE=$(printenv $VAR_IMAGE_NAME)
	export VAR_TAG=${ENTITY_UPPER}_IMAGE_TAG_${PROCESSOR_UPPER}
	export TAG=$(printenv $VAR_TAG)
	export MANIFEST=prepull-daemonset-${ENTITY}-${PROCESSOR}.yaml
	cat prepull-daemonset.yaml-template | envsubst > $MANIFEST

	cat $MANIFEST

	if [ "$ACTION" == "start" ]; then
		CMD="kubectl apply -f ./${MANIFEST}"
	elif [ "$ACTION" == "describe" ]; then
		CMD="kubectl describe -f ./${MANIFEST}"
	elif [ "$ACTION" == "status" ]; then
		CMD="kubectl get -f ./${MANIFEST}"
	elif [ "$ACTION" == "stop" ]; then
		CMD="kubectl delete -f ./${MANIFEST}"
	else
		echo ""
		echo "Invalid action: $ACTION"
		CMD=""
	fi

	echo "$CMD"

	eval "$CMD"
fi
