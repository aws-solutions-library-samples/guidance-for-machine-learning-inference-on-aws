######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

import os
import argparse
import time
import numpy as np
import requests
import json
import sys
import random
from concurrent import futures
import socket
import traceback
from urllib.parse import urlparse

# from essential_generators import DocumentGenerator
# num_instance = 4
# num_model_per_instance = 10
# http://instance-[INSTANCE_IDX].scale.svc.cluser.local:8000/predictions/model-[MODEL_IDX]
# INSTANCE_IDX = 0 to 3
# MODEL_IDX = 0 to 9

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--url', help='Model URL', type=str,
                        default=f'http://localhost:8080/predictions/model0')
    # parser.add_argument('--url', help='FastAPI model URL', type=str, default=f'http://instance[INSTANCE_IDX].scale.svc.cluser.local:8000/predictions/model[MODEL_IDX]')
    parser.add_argument('--num_thread', type=int, default=2, help='Number of threads invoking the model URL')
    # parser.add_argument('--sequence_length', type=int, default=512)
    parser.add_argument('--latency_window_size', type=int, default=250)
    parser.add_argument('--throughput_time', type=int, default=180)
    parser.add_argument('--throughput_interval', type=int, default=10)
    parser.add_argument('--is_multi_instance', default=False, action='store_true')
    parser.add_argument('--n_instance', required=False, type=int)
    parser.add_argument('--is_multi_model_per_instance', default=False, action='store_true')
    parser.add_argument('--n_model_per_instance', required=False, type=int)
    parser.add_argument('--post', default=False, action='store_true')
    parser.add_argument('--verbose', default=False, action='store_true')
    parser.add_argument('--cache_dns', default=False, action='store_true')
    parser.add_argument('--model_server', help="Model server: fastapi | triton | torchserve", default="fastapi")

    args, leftovers = parser.parse_known_args()

    is_multi_instance = args.is_multi_instance
    n_instance = 0
    if is_multi_instance:
        n_instance = args.n_instance
    n_model_per_instance = 0
    is_multi_model_per_instance = args.is_multi_model_per_instance
    if is_multi_model_per_instance:
        n_model_per_instance = args.n_model_per_instance
    model_server=args.model_server

    data = {}
    headers = {}
    if model_server == 'fastapi':
        data = {'seq_0': "How many chapters does the book have?",
                'seq_1': """The number 42 is, in The Hitchhiker's Guide to the Galaxy by Douglas Adams."""}
    elif model_server == 'triton':
        data = {"inputs":[{"name":"seq_0","shape":[1,1],"datatype":"BYTES","data":["What does the little engine say"]},{"name":"seq_1","shape":[1,1],"datatype":"BYTES","data":["In the childrens story about the little engine a small locomotive is pulling a large load up a mountain. Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: \"I think I can\" as it is pulling the heavy load all the way to the top of the mountain. On the way down it says: \"I thought I could\"."]}]}
        headers = {'Content-Type': 'application/json'}

    live = True
    num_infer = 0
    latency_list = []
    ret_status_failure_list = []
    latency_map = {}
    ret_status_failure_map = {}
    dns_cache = ['']
    if is_multi_instance:
        dns_cache = ['']*n_instance

    def single_request(pred, feed_data):
        session = requests.Session()
        pred_replace = pred
        idx_instance = 0
        idx_model_per_instance = None
        if is_multi_instance:
            idx_instance = random.choice(range(n_instance))
            pred_replace = pred_replace.replace('[INSTANCE_IDX]', str(idx_instance))
        if is_multi_model_per_instance:
            idx_model_per_instance = random.choice(range(n_model_per_instance))
            if model_server == "triton":
                idx_model_per_instance=idx_model_per_instance+1
            pred_replace = pred_replace.replace('[MODEL_IDX]', str(idx_model_per_instance))
        print(args)
        if args.cache_dns:
            print('caching dns')
            print(pred_replace)
            hostip = dns_cache[idx_instance]
            urlparts = urlparse(pred_replace)
            if hostip == '':
                hostname = urlparts.hostname
                hostip = socket.gethostbyname(hostname)
                dns_cache[idx_instance] = hostip
            port = ''
            if urlparts.port != None:
                port = f":{urlparts.port}"
            pred_replace = f"{urlparts.scheme}://{hostip}{port}{urlparts.path}"
        if args.verbose:
            print(pred_replace)
        if args.post:
            if model_server == "triton": 
                result = session.post(pred_replace, headers=headers, data=json.dumps(feed_data))
            else:
                result = session.post(pred_replace, data=feed_data)
        else:
            result = session.get(pred_replace)
        print(result)
        sys.stdout.flush()


    def one_thread(pred, feed_data):
        global latency_list
        global ret_status_failure_list
        global latency_map
        global num_infer
        global live
        global dns_cache
        session = requests.Session()
        while True:
            start = time.time()
            pred_replace = pred
            idx_instance = 0
            idx_model_per_instanc = None
            if is_multi_instance:
                idx_instance = random.choice(range(n_instance))
                pred_replace = pred_replace.replace('[INSTANCE_IDX]', str(idx_instance))
            if is_multi_model_per_instance:
                idx_model_per_instance = random.choice(range(n_model_per_instance))
                if model_server == "triton":
                    idx_model_per_instance=idx_model_per_instance+1
                pred_replace = pred_replace.replace('[MODEL_IDX]', str(idx_model_per_instance))
            if args.cache_dns:
                hostip = dns_cache[idx_instance]
                urlparts = urlparse(pred_replace)
                if hostip == '':
                    hostname = urlparts.hostname
                    hostip = socket.gethostbyname(hostname)
                    dns_cache[idx_instance] = hostip
                port = ''
                if urlparts.port != None:
                    port = f":{urlparts.port}"
                pred_replace = f"{urlparts.scheme}://{hostip}{port}{urlparts.path}"
            if args.post:
                if model_server == "triton":
                    result = session.post(pred_replace, headers=headers, data=json.dumps(feed_data))
                else:
                    result = session.post(pred_replace, data=feed_data)
            else:
                result = session.get(pred_replace)
            latency = time.time() - start
            latency_list.append(latency)

            map_key = '%s_%s' % (idx_instance, idx_model_per_instance)
            if map_key not in latency_map:
                latency_map[map_key] = []
            latency_map[map_key].append(latency)

            if result.status_code != 200:
                ret_status_failure_list.append(result.status_code)
                if map_key not in ret_status_failure_map:
                    ret_status_failure_map[map_key] = []
                ret_status_failure_map[map_key].append(result.status_code)


            num_infer += 1
            if not live:
                break

    def current_performance():
        try:
            last_num_infer = num_infer
            for _ in range(args.throughput_time // args.throughput_interval):
                current_num_infer = num_infer
                throughput = (current_num_infer - last_num_infer) / args.throughput_interval
                p50 = 0.0
                p90 = 0.0
                p95 = 0.0
                if latency_list:
                    p50 = np.percentile(latency_list[-args.latency_window_size:], 50)
                    p90 = np.percentile(latency_list[-args.latency_window_size:], 90)
                    p95 = np.percentile(latency_list[-args.latency_window_size:], 95)

                dump_output = {
                    'pid': os.getpid(),
                    'throughput': throughput,
                    'p50': '%.3f' % (p50),
                    'p90': '%.3f' % (p90),
                    'p95': '%.3f' % (p95),
                    'errors': '%d'%(len(ret_status_failure_list))
                }
                print(dump_output)
                if args.verbose:
                    # To prevent the error dictionary changed during iteration
                    lm_key_list = list(latency_map.keys())
                    print({'p90_%s' % x: '%0.3f' % (np.percentile(latency_map[x], 90)) for x in lm_key_list})
                    print({'num_%s' % x: len(latency_map[x]) for x in lm_key_list})
                    if(len(ret_status_failure_list) > 0):
                        rs_key_list = list(ret_status_failure_map.keys())
                        print(dict(zip(*np.unique(ret_status_failure_list, return_counts=True))))
                        print({'error_%s'% x: dict(zip(*np.unique(ret_status_failure_map[x], return_counts=True))) for x in rs_key_list})
                    print()

                sys.stdout.flush()
                last_num_infer = current_num_infer
                time.sleep(args.throughput_interval)
            global live
            live = False
        except:
            traceback.print_exc()


    # Single Request to debug the package being sent
    single_request(args.url, data)
    with futures.ThreadPoolExecutor(max_workers=args.num_thread + 1) as executor:
        executor.submit(current_performance)
        for _ in range(args.num_thread):
            executor.submit(one_thread, args.url, data)

