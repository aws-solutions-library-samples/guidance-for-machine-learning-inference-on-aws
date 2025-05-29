# Overview
This document describes the changes needed to showcase custom metrics autoscaling with Triton inference server in combination with [this](https://bit.ly/aws-custom-metrics-autoscaling) example from the [aws-do-eks](https://bit.ly/do-eks) project.

# Original URL
curl -X POST http://bert-base-multilingual-cased-gpu-0.default.svc.cluster.local:8080/v2/models/bert-base-multilingual-cased-1/infer --header 'Content-Type: application/json' --data-raw '{"inputs":[{"name":"seq_0","shape":[1,1],"datatype":"BYTES","data":["What does the little engine say"]},{"name":"seq_1","shape":[1,1],"datatype":"BYTES","data":["In the childrens story about the little engine a small locomotive is pulling a large load up a mountain. Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: \"I think I can\" as it is pulling the heavy load all the way to the top of the mountain. On the way down it says: \"I thought I could\"."]}]}'

# Traefik URL
curl -X POST -H "Host: bert.do.aws.dev" http://traefik.traefik.svc.cluster.local:80/v2/models/bert-base-multilingual-cased-1/infer --header 'Content-Type: application/json' --data-raw '{"inputs":[{"name":"seq_0","shape":[1,1],"datatype":"BYTES","data":["What does the little engine say"]},{"name":"seq_1","shape":[1,1],"datatype":"BYTES","data":["In the childrens story about the little engine a small locomotive is pulling a large load up a mountain. Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: \"I think I can\" as it is pulling the heavy load all the way to the top of the mountain. On the way down it says: \"I thought I could\"."]}]}'

# Custom metric
traefik_service_requests_total{code="200",method="POST",protocol="http",service="default-bert-base-multilingual-cased-gpu-0-8080@kubernetes"}
