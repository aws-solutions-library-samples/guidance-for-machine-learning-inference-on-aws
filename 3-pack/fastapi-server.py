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
sequence_length=config['global']['sequence_length']
processor=config['global']['processor']
pipeline_cores=config['global']['pipeline_cores']
batch_size=config['global']['batch_size']
default_question = "What does the little engine say"
default_context = """In the childrens story about the little engine a small locomotive is pulling a large load up a mountain.
    Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story 
    about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: 'I think I can' as it is 
    pulling the heavy load all the way to the top of the mountain. On the way down it says: I thought I could."""

# Read runtime configuration from environment
postprocess=True
if (os.getenv("POSTPROCESS",'True').lower() in ['false','0']):
    postprocess=False
quiet=False
if (os.getenv("QUIET","False").lower() in ['true','1']):
    quiet=True
num_models=1
try:
    num_models=int(os.getenv("NUM_MODELS", '1'))
except ValueError:
    logger.warning(f"Failed to parse environment variable NUM_MODELS={os.getenv('NUM_MODELS')}")
    logger.warning("Please ensure if set NUM_MODELS is a numeric value. Assuming value of 1")

# Detect runtime device type inf1, inf2, gpu, cpu, or arm
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
async def infer(model_id, seq_0: Optional[str] = default_question, seq_1: Optional[str] = default_context):
    question=seq_0
    context=seq_1
    status=200
    if model_id in models.keys():
        if not quiet:
            logger.warning(f"\nQuestion: {question}\n")
        tokenizer=tokenizers[model_id]
        encoded_input = tokenizer.encode_plus(question, context, return_tensors='pt', max_length=128, padding='max_length', truncation=True)
        if processor=='gpu':
            encoded_input.to(device)
        model=models[model_id]
        model_input = (encoded_input['input_ids'],  encoded_input['attention_mask'])
        output=model(*model_input) # This is specific to Inferentia
        answer_text = str(output[0])
        if postprocess:
            answer_start = torch.argmax(output[0])
            answer_end = torch.argmax(output[1])+1
            if (answer_end > answer_start):
                answer_text = tokenizer.convert_tokens_to_string(tokenizer.convert_ids_to_tokens(encoded_input["input_ids"][0][answer_start:answer_end]))
            else:
                answer_text = tokenizer.convert_tokens_to_string(tokenizer.convert_ids_to_tokens(encoded_input["input_ids"][0][answer_start:]))
        if not quiet:
            logger.warning("\nAnswer: ")
            logger.warning(answer_text)
    else:
        status=404
        answer_text = f"Model {model_id} does not exist. Try a model name up to model{num_models-1}"
        if not quiet:
            logger.warning(answer_text)
    return responses.JSONResponse(status_code=status, content={"detail": answer_text})

# Load models in memory and onto accelerator as needed
model_suffix = "bs"+batch_size+"_seq"+sequence_length+"_pc"+pipeline_cores+"_"+processor
model_path=os.path.join(path_prefix,'models',model_name + model_suffix + ".pt")
logger.warning(f"Loading {num_models} instances of pre-trained model {model_name} from path {model_path} ...")
tokenizers={}
models={}
transformers = importlib.import_module("transformers")
tokenizer_class = getattr(transformers, tokenizer_class_name)
for i in range(num_models):
    model_id = 'model' + str(i)
    logger.warning(f"   {model_id} ...")
    tokenizers[model_id]=tokenizer_class.from_pretrained(model_name)
    models[model_id] = torch.jit.load(model_path)
    if device_type=='gpu':
        model=models[model_id]
        model.to(device)
    elif device_type in ['inf1', 'inf2']:
        infer(model_id, default_question, default_context)
        logger.warning("    ... warmup completed")
