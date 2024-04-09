import ast
import json
import logging
import os

import torch
import transformers
from transformers import (
    AutoModelForQuestionAnswering,
    AutoTokenizer,
)
from optimum.bettertransformer import BetterTransformer

from ts.torch_handler.base_handler import BaseHandler

logger = logging.getLogger(__name__)
logger.info("Transformers version %s", transformers.__version__)


class TransformersSeqClassifierHandler(BaseHandler):
    """
    Transformers handler class for sequence, token classification and question answering.
    """

    def __init__(self):
        super(TransformersSeqClassifierHandler, self).__init__()
        self.initialized = False

    def initialize(self, ctx):
        """In this initialize function, the BERT model is loaded and
        the Layer Integrated Gradients Algorithm for Captum Explanations
        is initialized here.
        Args:
            ctx (context): It is a JSON Object containing information
            pertaining to the model artifacts parameters.
        """
        self.manifest = ctx.manifest
        properties = ctx.system_properties
        model_dir = properties.get("model_dir")
        model_weights_dir = ctx.model_yaml_config["handler"]["model_dir"]

        self.device = torch.device(
            "cuda:" + str(properties.get("gpu_id"))
            if torch.cuda.is_available() and properties.get("gpu_id") is not None
            else "cpu"
        )
        # read configs for the mode, model_name, etc. from setup_config.json
        setup_config_path = os.path.join(model_dir, "setup_config.json")
        if os.path.isfile(setup_config_path):
            with open(setup_config_path) as setup_config_file:
                self.setup_config = json.load(setup_config_file)
        else:
            logger.warning("Missing the setup_config.json file.")

        # Loading the model and tokenizer from checkpoint and config files based on the user's choice of mode
        # further setup config can be added.
        if self.setup_config["save_mode"] == "torchscript":
            serialized_file = "traced_model.pt"
            model_pt_path = os.path.join(model_weights_dir, serialized_file)
            self.model = torch.jit.load(model_pt_path, map_location=self.device)
        elif self.setup_config["save_mode"] == "pretrained":
            self.model = AutoModelForQuestionAnswering.from_pretrained(model_weights_dir)

            try:
                self.model = BetterTransformer.transform(self.model)
            except RuntimeError as error:
                logger.warning(
                    "HuggingFace Optimum is not supporting this model,for the list of supported models, please refer to this doc,https://huggingface.co/docs/optimum/bettertransformer/overview"
                )
        self.model.to(self.device)

        if self.setup_config["save_mode"] == "pretrained":
            self.tokenizer = AutoTokenizer.from_pretrained(
                    self.setup_config["model_name"],
                    do_lower_case=self.setup_config["do_lower_case"],
            )
        else:
            self.tokenizer = AutoTokenizer.from_pretrained(
                model_dir,
                do_lower_case=self.setup_config["do_lower_case"],
            )

        self.model.eval()
        logger.info("Transformer model from path %s loaded successfully", model_dir)

        self.initialized = True

    def preprocess(self, requests):
        """Basic text preprocessing, based on the user's chocie of application mode.
        Args:
            requests (str): The Input data in the form of text is passed on to the preprocess
            function.
        Returns:
            list : The preprocess function returns a list of Tensor for the size of the word tokens.
        """
        input_ids_batch = None
        attention_mask_batch = None
        logger.info(f"req: {requests}")
        for idx, input_text in enumerate(requests):
            max_length = self.setup_config["max_length"]
            logger.info("Received text: '%s'", input_text)

            question = input_text["seq_0"].decode("utf-8")
            context = input_text["seq_1"].decode("utf-8")
            logger.info(f" question: {question}")
            logger.info(f"context: {context}")
            inputs = self.tokenizer.encode_plus(
                question,
                context,
                max_length=int(max_length),
                padding='max_length',
                add_special_tokens=True,
                return_tensors="pt",
                truncation=True
            )
            input_ids = inputs["input_ids"].to(self.device)
            attention_mask = inputs["attention_mask"].to(self.device)
            # making a batch out of the recieved requests
            # attention masks are passed for cases where input tokens are padded.
            if input_ids.shape is not None:
                if input_ids_batch is None:
                    input_ids_batch = input_ids
                    attention_mask_batch = attention_mask
                else:
                    input_ids_batch = torch.cat((input_ids_batch, input_ids), 0)
                    attention_mask_batch = torch.cat(
                        (attention_mask_batch, attention_mask), 0
                    )
        return (input_ids_batch, attention_mask_batch)

    def inference(self, input_batch):
        """Predict the class (or classes) of the received text using the
        serialized transformers checkpoint.
        Args:
            input_batch (list): List of Text Tensors from the pre-process function is passed here
        Returns:
            list : It returns a list of the predicted value for the input text
        """
        input_ids_batch, attention_mask_batch = input_batch
        inferences = []
        # the output should be only answer_start and answer_end
        # we are outputing the words just for demonstration.
        output = self.model(
            input_ids_batch, attention_mask_batch
        )
        answer_text = str(output[0])
        answer_start = torch.argmax(output[0])
        answer_end = torch.argmax(output[1])+1
        if (answer_end > answer_start):
            answer_text = self.tokenizer.convert_tokens_to_string(self.tokenizer.convert_ids_to_tokens(input_ids_batch[0][answer_start:answer_end]))
        else:
            answer_text = self.tokenizer.convert_tokens_to_string(self.tokenizer.convert_ids_to_tokens(input_ids_batch[0][answer_start:]))
        inferences.append(answer_text)
        logger.info("Model predicted: '%s'", answer_text)


        print("Generated text", inferences)
        return inferences

    def postprocess(self, inference_output):
        """Post Process Function converts the predicted response into Torchserve readable format.
        Args:
            inference_output (list): It contains the predicted response of the input text.
        Returns:
            (list): Returns a list of the Predictions and Explanations.
        """
        return inference_output
