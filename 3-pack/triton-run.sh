#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

# Uncomment the infinate loop below to start an idle container locally while developing or troubleshooting
#while true; do date; sleep 10; done

tritonserver --model-repository=/app/server/models

