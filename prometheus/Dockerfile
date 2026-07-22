FROM prom/prometheus:v3.13.0

USER root

COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY rules/ /etc/prometheus/rules/

RUN chown -R nobody:nobody \
    /etc/prometheus/prometheus.yml \
    /etc/prometheus/rules

USER nobody