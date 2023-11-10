ARG BASE_IMAGE

FROM $BASE_IMAGE

ARG MODEL_NAME
ARG MODEL_FILE_NAME
ARG PROCESSOR

LABEL description="Model $MODEL_NAME packed in a FastAPI Server container to run on $PROCESSOR"

RUN mkdir -p /app/server/models

COPY ./config.properties /app/config.properties

COPY  ./3-pack/fastapi-server.py /app/server/fastapi-server.py

COPY ./3-pack/run.sh /app/server/run.sh

COPY ./3-pack/requirements.txt /app/server/requirements.txt

COPY ./llama_model/serialized /app/server/models

RUN pip install -r /app/server/requirements.txt

WORKDIR /app/server

EXPOSE 8080

CMD ["./run.sh"]
