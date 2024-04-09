import json
import os
import sys

import torch
import transformers
from transformers import (
    AutoConfig,
    AutoModelForCausalLM,
    AutoModelForQuestionAnswering,
    AutoModelForSequenceClassification,
    AutoModelForTokenClassification,
    AutoTokenizer,
    set_seed,
)

print("Transformers version", transformers.__version__)
set_seed(1)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


def transformers_model_dowloader(
    mode,
    pretrained_model_name,
    do_lower_case,
    max_length,
    torchscript,
    hardware,
    batch_size,
):
    """This function, save the checkpoint, config file along with tokenizer config and vocab files
    of a transformer model of your choice.
    """
    print("Download model and tokenizer", pretrained_model_name)
    # loading pre-trained model and tokenizer
    config = AutoConfig.from_pretrained(
        pretrained_model_name, torchscript=torchscript
    )
    model = AutoModelForQuestionAnswering.from_pretrained(
        pretrained_model_name, config=config
    )
    tokenizer = AutoTokenizer.from_pretrained(
        pretrained_model_name, do_lower_case=do_lower_case
    )

    NEW_DIR = "./Transformer_model"
    try:
        os.mkdir(NEW_DIR)
    except OSError:
        print("Creation of directory %s failed" % NEW_DIR)
    else:
        print("Successfully created directory %s " % NEW_DIR)

    print(
        "Save model and tokenizer/ Torchscript model based on the setting from setup_config",
        pretrained_model_name,
        "in directory",
        NEW_DIR,
    )
    if save_mode == "pretrained":
        model.save_pretrained(NEW_DIR)
        tokenizer.save_pretrained(NEW_DIR)
    elif save_mode == "torchscript":
        dummy_input = "This is a dummy input for torch jit trace"
        question = "What does the little engine say?"

        context = """In the childrens story about the little engine a small locomotive is pulling a large load up a mountain.
            Since the load is heavy and the engine is small it is not sure whether it will be able to do the job. This is a story 
            about how an optimistic attitude empowers everyone to achieve more. In the story the little engine says: 'I think I can' as it is 
            pulling the heavy load all the way to the top of the mountain. On the way down it says: I thought I could."""
        inputs = tokenizer.encode_plus(
            question,
            context,
            max_length=int(max_length),
            padding='max_length',
            add_special_tokens=True,
            return_tensors="pt",
            truncation=True
        )
        model.to(device).eval()
        input_ids = inputs["input_ids"].to(device)
        attention_mask = inputs["attention_mask"].to(device)
        traced_model = torch.jit.trace(model, (input_ids, attention_mask))
        torch.jit.save(traced_model, os.path.join(NEW_DIR, "traced_model.pt"))
    return


if __name__ == "__main__":
    dirname = os.path.dirname(__file__)
    if len(sys.argv) > 1:
        filename = os.path.join(dirname, sys.argv[1])
    else:
        filename = os.path.join(dirname, "setup_config.json")
    f = open(filename)
    settings = json.load(f)
    mode = settings["mode"]
    model_name = settings["model_name"]
    do_lower_case = settings["do_lower_case"]
    max_length = settings["max_length"]
    save_mode = settings["save_mode"]
    if save_mode == "torchscript":
        torchscript = True
    else:
        torchscript = False
    hardware = settings.get("hardware")
    batch_size = int(settings.get("batch_size", "1"))

    transformers_model_dowloader(
        mode,
        model_name,
        do_lower_case,
        max_length,
        torchscript,
        hardware,
        batch_size,
    )
