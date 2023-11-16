######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

from typing import Optional
from fastapi import FastAPI,logger,responses
from configparser import ConfigParser
import torch, os, logging
import importlib
import platform
from transformers import AutoTokenizer
from transformers_neuronx.llama.model import LlamaForSampling

global device
global processor
global device_type
global model
global tokenizer
global logger
global postprocess
global default_question, default_context


logger = logging.getLogger()

# Read static configuration from config.properties
logger.warning("\nParsing configuration ...")
path_prefix = os.path.dirname(__file__)
with open(path_prefix + '/../config.properties') as f:
    config_lines = '[global]\n' + f.read()
    f.close()
config = ConfigParser()
config.read_string(config_lines)
model_name = config['global']['huggingface_model_name']
tokenizer_class_name = config['global']['huggingface_tokenizer_class'] 
model_class_name = config['global']['huggingface_model_class']
neuron_model_class_name = config['global']['neuron_model_class']
sequence_length=int(config['global']['sequence_length'])
processor=config['global']['processor']
pipeline_cores=int(config['global']['pipeline_cores'])
batch_size=int(config['global']['batch_size'])
default_prompts = ["My name is Mike and"]*batch_size
tp_degree=int(config['global']['tp_degree'])
amp_type=config['global']['amp_type']

# Read runtime configuration from environment
quiet=False
if (os.getenv("QUIET","False").lower() in ['true','1']):
    quiet=True
num_models=1
try:
    num_models=int(os.getenv("NUM_MODELS", '1'))
except ValueError:
    logger.warning(f"Failed to parse environment variable NUM_MODELS={os.getenv('NUM_MODELS')}")
    logger.warning("Please ensure if set NUM_MODELS is a numeric value. Assuming value of 1")

# Detect runtime device type inf2, gpu, cpu, or arm
device_type=""

try:
    import torch_neuron
    device_type="inf1"
except ImportError:
    logger.warning("Inf1 chip not detected")
    pass
try:
    import torch_neuronx
    device_type = 'inf2'
except ImportError:
    print('[WARN] Inf2 device not found')
    pass


if device_type in ['inf1', 'inf2']:
    pass
elif torch.cuda.is_available():
    device_type="gpu"
    device = torch.device("cuda")
    logger.warning(torch.cuda.get_device_name(0))
else:
    machine=platform.uname().machine
    device_type="cpu"
    if machine == 'aarch64':
        device_type="arm"
    device = torch.device("cpu")

if processor != device_type:
    logger.warning(f"Configured target processor {processor} differs from actual processor {device_type}")
logger.warning(f"Running models on processor: {device_type}")


# FastAPI server
app = FastAPI()

# Server healthcheck
@app.get("/")
async def read_root():
    return {"Status": "Healthy"}

# Model inference API endpoint
@app.get("/predictions/{model_id}")
async def infer(model_id, seqs: Optional[list] = default_prompts):
    prompts=seqs
    status=200
    if model_id in models.keys():
        if not quiet:
            logger.warning(f"\nQuestion: {prompts}\n")

        tokenizer = tokenizers[model_id]
        tokens = tokenizer(prompts, return_tensors="pt")
        neuron_model=models[model_id]
        generated_sequences = neuron_model.sample(tokens.input_ids, sequence_length=sequence_length, top_k=50)
        generated_sequences = [tokenizer.decode(seq) for seq in generated_sequences]

        if not quiet:
            logger.warning("\nAnswer: ")
            logger.warning(generated_sequences)
    else:
        status=404
        generated_sequences = f"Model {model_id} does not exist. Try a model name up to model{num_models-1}"
        if not quiet:
            logger.warning(generated_sequences)
    return responses.JSONResponse(status_code=status, content={"detail": generated_sequences})

# Load models in memory and onto accelerator as needed
#model_suffix = "_bs"+batch_size+"_seq"+sequence_length+"_pc"+pipeline_cores+"_"+processor
#model_path=os.path.join(path_prefix,'models',model_name + model_suffix + ".pt")
#logger.warning(f"Loading {num_models} instances of pre-trained model {model_name} from path {model_path} ...")

# set neuron environment variable
os.environ["NEURON_CC_FLAGS"] = "--model-type=transformer-inference"
os.environ['NEURON_RT_NUM_CORES'] = str(tp_degree)
os.environ["NEURONX_CACHE"]= "on"
os.environ["NEURONX_DUMP_TO"] = f"/app/server/models/tp{tp_degree}_bs{batch_size}_seqlen{sequence_length}"

model_dir = "/app/server/models" # [TODO], hard-coded, to add to config.properties
tokenizer_dir = "/app/server/models" # tokenizer in the same directory as model

serialized_model_dir = os.path.join(model_dir, 'serialized')
os.makedirs(serialized_model_dir, exist_ok=True)

tokenizers={}
models={}
transformers = importlib.import_module("transformers")
tokenizer_class = getattr(transformers, tokenizer_class_name)
transformers_neuronx = importlib.import_module("transformers_neuronx")
#neuron_model_class = getattr(transformers_neuronx, neuron_model_class_name)

for i in range(num_models):
    model_id = 'model' + str(i)
    logger.warning(f"   {model_id} ...")
    tokenizer = AutoTokenizer.from_pretrained(tokenizer_dir)
    tokenizers[model_id]=tokenizer
    if device_type in ['inf2']:
        #models[model_id] = neuron_model_class.from_pretrained(serialized_model_dir, tp_degree=tp_degree, batch_size=batch_size, amp=amp_type)
        models[model_id] = LlamaForSampling.from_pretrained(serialized_model_dir, tp_degree=tp_degree, batch_size=batch_size, amp=amp_type)
        neuron_model = models[model_id]
        neuron_model.to_neuron() # compile model and load weights into device memory
        infer(model_id, default_prompts)
        logger.warning("    ... warmup completed")
    else:
        logger.warning("    ... inference other than inf2 needs to be added")



