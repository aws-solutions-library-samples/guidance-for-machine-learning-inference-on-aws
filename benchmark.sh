#!/bin/bash

echo ""
echo "Running benchmark tests ..."

for num in 8 4 2 1; do
	echo ""
	echo "Testing with $num clients ..."
	sed -e "s/^\(num_test_containers=*\).*/num_test_containers=$num/g" config.properties > config.properties-tmp
	mv config.properties config.properties-bak
	mv config.properties-tmp config.properties
	cat config.properties | grep num_test_containers
	./test.sh run bmk
	status=Running
	while [ ! "$status" == "Completed" ]; do
		echo "Waiting for benchmark test with $num clients to complete"
		sleep 5
		num_completed=$(kubectl get pods | grep test | grep Completed | wc -l | xargs)
		if [ "$num_completed" == "$num" ]; then
			status=Completed
		fi
	done
	echo ""
	echo "Test with $num clients completed, analyzing results ..."
	./test.sh run bma
	echo ""
	echo "Stopping test with $num clients ..."
	./test.sh stop
done

echo ""
echo "Done running benchmark tests."
echo ""

