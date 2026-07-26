FROM prom/prometheus:v3.13.0

USER root

COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY rules/ /etc/prometheus/rules/
COPY entrypoint.sh /usr/local/bin/prometheus-entrypoint.sh

RUN command -v wget >/dev/null \
    && chmod 0755 /usr/local/bin/prometheus-entrypoint.sh \
    && chown -R nobody:nobody \
        /etc/prometheus/prometheus.yml \
        /etc/prometheus/rules \
        /usr/local/bin/prometheus-entrypoint.sh

USER nobody

ENTRYPOINT ["/usr/local/bin/prometheus-entrypoint.sh"]