ARG BASE_IMAGE

FROM $BASE_IMAGE

RUN mkdir -p /app/tests

COPY config.properties /app

ADD ./5-test/tests /app/tests

CMD ["bash","-c","while true; do date; sleep 10; done"]
