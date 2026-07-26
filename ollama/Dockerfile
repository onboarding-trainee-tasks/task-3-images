FROM alpine:3.20 AS model-stage

WORKDIR /model

COPY models/models/ ./

FROM ollama/ollama:0.32.1

ENV OLLAMA_HOST=0.0.0.0:11434
ENV OLLAMA_MODELS=/root/.ollama/models

COPY --from=model-stage /model/ /root/.ollama/models/

EXPOSE 11434