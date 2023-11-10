import os
import importlib
import torch
from configparser import ConfigParser
from transformers_neuronx.llama.model import LlamaForSampling
from transformers import AutoModelForCausalLM
from transformers_neuronx.module import save_pretrained_split
tp_degree = 2
batch_size = 1
sequence_length = 256
amp_type = 'bf16'
os.environ["NEURON_CC_FLAGS"] = "--model-type=transformer-inference"
os.environ['NEURON_RT_NUM_CORES'] = str(tp_degree)
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
#transformers_neuronx = importlib.import_module("transformers_neuronx")
#neuron_model_class = getattr(transformers_neuronx, neuron_model_class_name)
neuron_model = LlamaForSampling.from_pretrained(serialized_model_dir, tp_degree=tp_degree, batch_size=batch_size, amp=amp_type)
# compile model for neuron
neuron_model.to_neuron()
