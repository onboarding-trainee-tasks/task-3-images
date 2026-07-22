FROM alpine/ollama:0.32.1

ENV OLLAMA_HOST=0.0.0.0:11434
ENV OLLAMA_MODELS=/root/.ollama/models

COPY models/models/ /root/.ollama/models/
EXPOSE 11434