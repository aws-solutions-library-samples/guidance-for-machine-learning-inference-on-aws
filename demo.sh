#!/bin/bash


######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

source ./config.properties

print_help() {
	echo ""
	echo "Usage: $0 <arg>"
	echo ""
	echo "   When no arguments are specified, this script runs the demo loop "
	echo "   ./deploy.sh run &&./test.sh run bmk && ./test.sh run bma && ./test.sh stop && ./deploy.sh stop "
	echo "   to continuously cycle load on the target processor."
	echo ""
	echo "   Available optional arguments:"
	echo "      run      - [default] run the demo loop"
	echo "      status   - show current status of the demo looppull base image from container registry"
	echo "      logs     - show full demo logs"
	echo "      metrics  - show demo metrics including performance information"
	echo "      clear    - clear historical demo logs and metrics demo metrics"
	echo "      stop     - stop demo loop"
        echo ""
}


LOG=/tmp/inference-demo.log
METRICS=/tmp/inference-metrics.log

run() {
    status=$(ps -aef | grep -v grep | grep demo | grep run | wc -l)
    if [ $status -gt 2 ]; then
	echo ""
	echo "A demo is already running."
        echo "Please run './demo.sh stop' first, then try again."
    else
	echo "" >> $LOG
	echo "Starting demo loop ..." >> $LOG

	while true; do
		echo "" >> $LOG
		echo "Starting demo run ..." >> $LOG
		date >> $LOG
		./deploy.sh run >> $LOG
		cnt_model_servers_deployed=$(./deploy.sh status | grep ${processor}- | grep -v TCP | wc -l)
		cnt_model_servers_running=$(./deploy.sh status | grep ${processor}- | grep Running | wc -l)
		echo "Model servers deployed: $cnt_model_servers_deployed" >> $LOG
		echo "Model servers running:  $cnt_model_servers_running" >> $LOG
		while [ $cnt_model_servers_running -lt $cnt_model_servers_deployed ]; do
			sleep 10
			cnt_model_servers_deployed=$(./deploy.sh status | grep ${processor}- | grep -v TCP | wc -l)
			cnt_model_servers_running=$(./deploy.sh status | grep ${processor}- | grep Running | wc -l)
			echo "Model servers deployed: $cnt_model_servers_deployed" >> $LOG
			echo "Model servers running:  $cnt_model_servers_running" >> $LOG
		done
		./test.sh stop 2>/dev/null >> $LOG
		sleep 10
		./test.sh run bmk >> $LOG
		sleep 10
		cnt_in_progress_bmk=$(./test.sh status | grep test | grep -v Completed | grep -v Error | wc -l)
		echo "In-progress benchmark tests: $cnt_in_progress_bmk" >> $LOG
		while [ $cnt_in_progress_bmk -gt 0 ]; do
			sleep 30
			cnt_in_progress_bmk=$(./test.sh status | grep test | grep -v Completed | grep -v Error | wc -l)
			echo "In-progress benchmark tests: $cnt_in_progress_bmk" >> $LOG
		done
		./deploy.sh stop >> $LOG
		cnt_model_servers_deployed=$(./deploy.sh status | grep ${processor}- | wc -l)
		echo "Model servers deployed: $cnt_model_servers_deployed" >> $LOG
		while [ $cnt_model_servers_deployed -gt 0 ]; do
			sleep 10
			cnt_model_servers_deployed=$(./deploy.sh status | grep ${processor}- | wc -l)
			echo "Model servers deployed: $cnt_model_servers_deployed" >> $LOG
		done
		./test.sh run bma >> $LOG &
		sleep 5
		cnt_in_progress_bma=$(ps -aef | grep bma | grep -v grep | wc -l)
        	while [ $cnt_in_progress_bma -gt 0 ]; do
			echo "" >> $LOG
			echo "Benchmark analysis in progress ..." >> $LOG
			sleep 10
			cnt_in_progress_bma=$(ps -aef | grep bma | grep -v grep | wc -l)	
		done
		date >> $METRICS
		tail -n 30 $LOG | grep throughput_total >> $METRICS
		echo "Cooling off before next demo loop ... " >> $LOG
		sleep 60
		echo "Done cooling off" >> $LOG
	done
    fi
}

status() {
	ps -aef | grep demo | grep run
}

logs() {
	tail -f $LOG -n 100
}

metrics() {
	tail -f $METRICS
}

clear() {
	rm -vf $LOG
	rm -vf $METRICS
} 

stop() {
	pkill -e demo.sh
}

action=$1

if [ "$action" == "" ]
then
    print_help
else
    echo ""
    case "$action" in
        "run")
	    #echo "Running demo ..."
            run
            ;;
        "stop")
	    echo "Stopping demo ..."
            stop
            ;;
        "status")
	    echo "Showing demo status ..."
            status
            ;;
        "logs")
	    echo "Showing demo logs ..."
            logs
            ;;
        "metrics")
	    echo "Showing demo metrics ..."
            metrics
            ;;
        "clear")
	    echo "Clearing historical demo logs and metrics ..."
            clear
            ;;
        *)
	    echo "Showing demo help ..."
	    print_help
            ;;
    esac
    echo ""
fi
