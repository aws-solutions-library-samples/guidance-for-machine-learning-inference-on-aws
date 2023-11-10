######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

# Llama 2 model compilation

import os
import importlib
from configparser import ConfigParser
from transformers_neuronx.llama.model import LlamaForSampling
from transformers import AutoModelForCausalLM
from transformers_neuronx.module import save_pretrained_split
import torch
#global logger
#logger.warning("\nParsing configuration ...")
path_prefix = os.path.dirname(__file__)
with open(path_prefix + '/../config.properties') as f:
    config_lines = '[global]\n' + f.read()
    f.close()
config = ConfigParser()
config.read_string(config_lines)
sequence_length=config['global']['sequence_length']
batch_size=config['global']['batch_size']
tp_degree=config['global']['tp_degree']
amp_type=config['global']['amp_type']
neuron_model_class_name = config['global']['neuron_model_class']

# set neuron environment variable
#os.environ["NEURON_CC_FLAGS"] = "--model-type=transformer-inference --enable-experimental-O1"
os.environ["NEURON_CC_FLAGS"] = "--model-type=transformer-inference --O1"
os.environ['NEURON_RT_NUM_CORES'] = tp_degree
os.environ["NEURONX_CACHE"]= "on"
os.environ["NEURONX_DUMP_TO"] = f"./neuron_cache/tp{tp_degree}_bs{batch_size}_seqlen{sequence_length}"

# create a directory for model
model_dir = "/app/llama_model" # hugging face format
os.makedirs(model_dir, exist_ok=True)

# initialize the model
model = AutoModelForCausalLM.from_pretrained(model_dir, low_cpu_mem_usage=True, torch_dtype=torch.float16)

# serialize the model
serialized_model_dir = os.path.join(model_dir, 'serialized')
os.makedirs(serialized_model_dir, exist_ok=True)

save_pretrained_split(model, serialized_model_dir)

# create neuron model 
transformers_neuronx = importlib.import_module("transformers_neuronx")
#neuron_model_class = getattr(transformers_neuronx, neuron_model_class_name)
neuron_model = LlamaForSampling.from_pretrained(serialized_model_dir, tp_degree=int(config['global']['tp_degree']), batch_size=batch_size, amp=amp_type)

# compile model for neuron
neuron_model.to_neuron()


