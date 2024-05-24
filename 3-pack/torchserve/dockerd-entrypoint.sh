#!/bin/bash
set -e

if [[ "$1" = "serve" ]]; then
    shift 1

    pip install -r requirements.txt 
    python download_model.py
    torch-model-archiver --model-name BERTQA --version 1.0 --handler handler.py --config-file model-config.yaml --extra-files "./setup_config.json" --archive-format no-archive --export-path /home/model-server/model-store -f 
    mv Transformer_model /home/model-server/model-store/BERTQA/
    torchserve --start --ts-config /home/model-server/config.properties --models model0=BERTQA
else
    eval "$@"
fi

# prevent docker exit
tail -f /dev/null
