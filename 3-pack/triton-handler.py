import os

import numpy as np
import torch
import transformers
import triton_python_backend_utils as pb_utils

from configparser import ConfigParser
from datetime import datetime
import logging
import importlib
import platform

class TritonPythonModel:
    

    def initialize(self, args):
        self.logger = logging.getLogger()
        self.logger.warning("\nParsing configuration ...")
        self.path_prefix = os.path.dirname(__file__)
        with open('/app/config.properties') as f:
            config_lines = '[global]\n' + f.read()
            f.close()
        self.config = ConfigParser()
        self.config.read_string(config_lines)
        self.model_name = self.config['global']['huggingface_model_name']
        self.tokenizer_class_name = self.config['global']['huggingface_tokenizer_class']
        self.model_class_name = self.config['global']['huggingface_model_class']
        self.sequence_length=self.config['global']['sequence_length']
        self.processor=self.config['global']['processor']
        self.pipeline_cores=self.config['global']['pipeline_cores']
        self.batch_size=self.config['global']['batch_size']
        self.default_question = "What does the little engine say"
        self.default_context = """In the childrens story about the little engine a small locomotive is pulling a large load up a mountain.
            Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story 
            about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: 'I think I can' as it is 
            pulling the heavy load all the way to the top of the mountain. On the way down it says: I thought I could."""

        self.postprocess=True
        if (os.getenv("POSTPROCESS",'True').lower() in ['false','0']):
            self.postprocess=False
        self.quiet=False
        if (os.getenv("QUIET","False").lower() in ['true','1']):
            self.quiet=True
        self.num_models=1
        try:
            self.num_models=int(os.getenv("NUM_MODELS", '1'))
        except ValueError:
            self.logger.warning(f"Failed to parse environment variable NUM_MODELS={os.getenv('NUM_MODELS')}")
            self.logger.warning("Please ensure if set NUM_MODELS is a numeric value. Assuming value of 1")
        
        # Detect runtime device type inf1, inf2, gpu, cpu, or arm
        self.device_type=""
        
        try:
            import torch_neuron
            self.device_type="inf1"
        except ImportError:
            self.logger.warning("Inf1 chip not detected")
            pass
        try:
            import torch_neuronx
            self.device_type = 'inf2'
        except ImportError:
            print('[WARN] Inf2 device not found')
            pass
        
        if self.device_type in ['inf1', 'inf2']:
            pass
        elif torch.cuda.is_available():
            self.device_type="gpu"
            self.device = torch.device("cuda")
            self.logger.warning(torch.cuda.get_device_name(0))
        else:
            machine=platform.uname().machine
            self.device_type="cpu"
            if machine == 'aarch64':
                self.device_type="arm"
            self.device = torch.device("cpu")
        
        if self.processor != self.device_type:
            self.logger.warning(f"Configured target processor {self.processor} differs from actual processor {self.device_type}")
        self.logger.warning(f"Running models on processor: {self.device_type}")
        
        self.model_suffix = "_bs"+self.batch_size+"_seq"+self.sequence_length+"_pc"+self.pipeline_cores+"_"+self.processor
        self.model_path=os.path.join('/app/server/models',self.model_name + self.model_suffix + ".pt")
        self.logger.warning(f"Loading pre-trained model {self.model_name} from path {self.model_path} ...")
        transformers = importlib.import_module("transformers")
        tokenizer_class = getattr(transformers, self.tokenizer_class_name)
        self.tokenizer=tokenizer_class.from_pretrained(self.model_name)
        self.model = torch.jit.load(self.model_path)
        torch.jit.fuser('off')
        torch._C._jit_override_can_fuse_on_cpu(False)
        torch._C._jit_override_can_fuse_on_gpu(False)
        torch._C._jit_set_texpr_fuser_enabled(False)
        torch._C._jit_set_nvfuser_enabled(False)
        if self.device_type=='gpu':
            self.model.to(self.device)
        elif self.device_type in ['inf1', 'inf2']:
            self.answer(self.default_question, self.default_context)
            self.logger.warning("    ... warmup completed")
        

    def execute(self, requests):
        now = datetime.now()
        self.logger.warning(f"\nReceived {len(requests)} request(s) on {now}")
        responses = []
        for request in requests:
            # Assume inputs named "seq_0" and "seq_1"
            input_tensor_seq_0 = pb_utils.get_input_tensor_by_name(request, "seq_0")
            input_tensor_seq_1 = pb_utils.get_input_tensor_by_name(request, "seq_1")
            question = input_tensor_seq_0.as_numpy()[0][0].decode("utf-8")
            context = input_tensor_seq_1.as_numpy()[0][0].decode("utf-8")
            self.logger.warning(f"\nquestion={question}\ncontext={context}")
            
            if question == '' or context == '':
                self.logger.warning("Detected blank question or context. Using default.")
                question = self.default_question
                context = self.default_context
                self.logger.warning(f"\nquestion={question}\ncontext={context}")

            tstart=datetime.now()
            response = self.answer(question, context)
            tend=datetime.now()
            self.logger.warning(f"\nInference time elapsed: {tend-tstart}")
            responses.append(response)

        return responses

    def answer(self, question, context):
        status=200
        if not self.quiet:
            self.logger.warning(f"\nQuestion:\n{question}")
        encoded_input = self.tokenizer.encode_plus(question, context, return_tensors='pt', max_length=128, padding='max_length', truncation=True)
        if self.processor=='gpu':
            encoded_input.to(self.device)
        model_input = (encoded_input['input_ids'],  encoded_input['attention_mask'])
        output=self.model(*model_input)
        answer_text = str(output[0])
        if self.postprocess:
            answer_start = torch.argmax(output[0])
            answer_end = torch.argmax(output[1])+1
            if (answer_end > answer_start):
                answer_text = self.tokenizer.convert_tokens_to_string(self.tokenizer.convert_ids_to_tokens(encoded_input["input_ids"][0][answer_start:answer_end]))
            else:
                answer_text = self.tokenizer.convert_tokens_to_string(self.tokenizer.convert_ids_to_tokens(encoded_input["input_ids"][0][answer_start:]))
        if not self.quiet:
            self.logger.warning("\nAnswer: ")
            self.logger.warning(answer_text)
            
        pb_utils.InferenceResponse()
            
        tensor = pb_utils.Tensor("answer", np.array(answer_text, dtype=np.object_))
        response = pb_utils.InferenceResponse(output_tensors=[tensor])
        return response

    def finalize(self):
        print("Cleaning up...")
