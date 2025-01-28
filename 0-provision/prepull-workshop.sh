#!/bin/bash

help () {
	echo ""
	echo "Usage: $0 [ACTION]"
	echo "       ACTION - start(default), status, stop, help"
	echo ""
}

export ACTION=$1
if [ "$ACTION" == "" ]; then
	export ACTION=start
fi

if [ "$ACTION" == "help" ]; then
	help
elif [ "$ACTION" == "start" ]; then
	./prepull.sh start model inf
	./prepull.sh start model graviton
	./prepull.sh start test cpu
elif [ "$ACTION" == "status" ]; then
	CMD="kubectl get ds -A | grep -E 'READY|prepull'"
	echo ""
	echo "$CMD"
	eval "$CMD"
elif [ "$ACTION" == "stop" ]; then
	./prepull.sh stop model inf
	./prepull.sh stop model graviton
	./prepull.sh stop test cpu
else
	echo ""
	echo "Invalid action: $ACTION"
	help
fi
	
