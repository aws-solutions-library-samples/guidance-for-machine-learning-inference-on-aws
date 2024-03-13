#!/bin/bash

echo ""
echo "Starting demo loop ..."

while true; do
	echo "Starting demo run ..."	
	date
	./test.sh stop
	sleep 10
	./test.sh run bmk
	sleep 10
	cnt_in_progress_bmk=$(./test.sh status | grep test | grep -v Completed | wc -l)
	echo "In-progress benchmark tests: $cnt_in_progress_bmk"
	while [ $cnt_in_progress_bmk -gt 0 ]; do
		sleep 30
		cnt_in_progress_bmk=$(./test.sh status | grep test | grep -v Completed | wc -l)
		echo "In-progress benchmark tests: $cnt_in_progress_bmk"
	done
	./test.sh run bma
	cnt_in_progress_bma=$(ps -aef | grep bma | grep -v grep | wc -l)
        while [ $cnt_in_progress_bma -gt 0 ]; do
		echo "Benchmark analysis in progress ..."
		sleep 10
		cnt_in_progress_bma=$(ps -aef | grep bma | grep -v grep | wc -l)	
	done
done
