#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

if [ -f ../config.properties ]; then
    source ../config.properties
elif [ -f ./config.properties ]; then
    source ./config.properties
else
    echo "config.properties not found!"
fi

echo ""
echo "Aggregated statistics ..."
line_count=0
throughput_sum=0
p50_sum=0
p90_sum=0
p95_sum=0
errors_total=0
throughput_clients=$num_test_containers
while IFS='' read -r line; do
    line_count=$((line_count+1))
    throughput=$(echo $line | awk '{print $4}' | sed -e "s/,//g" | sed -e "s/'//g")
    p50=$(echo $line | awk '{print $6}' | sed -e "s/,//g" | sed -e "s/'//g")
    p90=$(echo $line | awk '{print $8}' | sed -e "s/,//g" | sed -e "s/'//g")
    p95=$(echo $line | awk '{print $10}' | sed -e "s/,//g" | sed -e "s/'//g")
    errors=$(echo $line | awk '{print $12}' | sed -e "s/}//g" | sed -e "s/'//g")
    throughput_sum=$( echo "$throughput_sum + $throughput" | bc )
    p50_sum=$( echo "$p50_sum + $p50" | bc)
    p90_sum=$( echo "$p90_sum + $p90" | bc)
    p95_sum=$( echo "$p95_sum + $p95" | bc)
    errors_total=$(echo "${errors_total} + $errors" | bc)
done < $1
echo 'Line count is:'$line_count
echo 'Throughputsum is:' $throughput_sum

throughput_total=$(echo "scale=1; $throughput_clients * ($throughput_sum / $line_count)" | bc)
p50_avg=$(echo "scale=3; $p50_sum / $line_count" | bc)
p90_avg=$(echo "scale=3; $p90_sum / $line_count" | bc)
p95_avg=$(echo "scale=3; $p95_sum / $line_count" | bc)
printf "{ 'throughput_total': %.1f, 'p50_avg': %.3f, 'p90_avg': %.3f, 'p95_avg': %.3f, 'errors_total': %.0f }\n" "$(echo $throughput_total)" "$(echo $p50_avg)" "$(echo $p90_avg)" "$(echo $p95_avg)" "$(echo $errors_total)"
