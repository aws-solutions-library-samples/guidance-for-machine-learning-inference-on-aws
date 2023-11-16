######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

import torch
import importlib
from configparser import ConfigParser

device_type='cpu'

try:
    import torch_neuron
    device_type='inf1'
except ImportError:
    print('[WARN] Torch Neuron not Found')
    pass
try:
    import torch_neuronx
    device_type='inf2'
except ImportError:
    print('[WARN] Torch Neuronx not Found')
    pass

import os

# 1. READ config.properties
print("\nParsing configuration ...")
path_prefix = os.getcwd()
with open(path_prefix + '/../config.properties') as f:
    config_lines = '[global]\n' + f.read()
    f.close()
config = ConfigParser()
config.read_string(config_lines)

model_name = config['global']['huggingface_model_name']
tokenizer_class_name = config['global']['huggingface_tokenizer_class']
model_class_name = config['global']['huggingface_model_class']
sequence_length=int(config['global']['sequence_length'])
processor=config['global']['processor']
pipeline_cores=config['global']['pipeline_cores']
batch_size=int(config['global']['batch_size'])
test=config['global']['test']

question = "What does the little engine say?"

context = """In the childrens story about the little engine a small locomotive is pulling a large load up a mountain.
    Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story 
    about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: 'I think I can' as it is 
    pulling the heavy load all the way to the top of the mountain. On the way down it says: I thought I could."""


# 2. LOAD PRE-TRAINED MODEL
print(f'\nLoading pre-trained model: {model_name}')
transformers = importlib.import_module("transformers")
tokenizer_class = getattr(transformers, tokenizer_class_name)
model_class = getattr(transformers, model_class_name)
tokenizer = tokenizer_class.from_pretrained(model_name)
model = model_class.from_pretrained(model_name, return_dict=False)

# 3. TOKENIZE THE INPUT
print('\nTokenizing input sample ...')
inputs = tokenizer.encode_plus(question,
                               context,
                               return_tensors="pt",
                               max_length=sequence_length,
                               padding='max_length',
                               truncation=True)
if device_type not in ['inf1', 'inf2']:
    if torch.cuda.is_available():
        device = torch.device("cuda")
        device_type = "gpu"
        model.to(device)
        inputs.to(device)
    else:
        device = torch.device("cpu")
        device_type = 'cpu'

if device_type == processor:
    print(f"   ... Using device: {device_type}")
else:
    print(f"[WARN] detected device_type ({device_type}) does not match the configured processor ({processor})")

# 2. COMPILE THE MODEL
print('\nTracing model ...')
example_inputs = (
    torch.cat([inputs['input_ids']] * batch_size,0), 
    torch.cat([inputs['attention_mask']] * batch_size,0)
)
os.makedirs(f'traced-{model_name}', exist_ok=True)
torch.set_num_threads(6)
if 'inf' in processor:
    model_traced = torch.neuron.trace(model, 
                                  example_inputs, 
                                  verbose=1, 
                                  compiler_workdir=f'./traced-{model_name}/compile_wd_{processor}_bs{batch_size}_seq{sequence_length}_pc{pipeline_cores}',  
                                  compiler_args = ['--neuroncore-pipeline-cores', str(pipeline_cores)])
elif 'inf2' in processor:
    model_traced = torch_neuronx.trace(model,
                                  example_inputs)
else:
    model_traced = torch.jit.trace(model, example_inputs)
    
# 3. TEST THE COMPILED MODEL (Optional)        
if test.lower() == 'true':
    print("\nTesting traced model ...")
    print(f"Question: {question}")
    # Testing the traced model
    answer_logits = model_traced(*example_inputs)
    answer_start = answer_logits[0].argmax().item()
    answer_end = answer_logits[1].argmax().item()+1
    answer_txt = ""
    if answer_end > answer_start:
        answer_txt = tokenizer.convert_tokens_to_string(tokenizer.convert_ids_to_tokens(inputs["input_ids"][0][answer_start:answer_end]))
    else:
        answer_txt = tokenizer.convert_tokens_to_string(tokenizer.convert_ids_to_tokens(inputs["input_ids"][0][answer_start:]))
    print(f'Model Answer: {answer_txt}')

# 4. SAVE THE COMPILED MODEL
print('\nSaving traced model ...')
model_path=f'./traced-{model_name}/{model_name}_{processor}_bs{batch_size}_seq{sequence_length}_pc{pipeline_cores}.pt'
model_traced.save(model_path)

print(f'Done. Model saved as: {model_path}')
