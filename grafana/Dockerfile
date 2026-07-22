FROM grafana/grafana:13.1.1

USER root

COPY provisioning/ /etc/grafana/provisioning/
COPY dashboards/ /var/lib/grafana/dashboards/

RUN chown -R grafana:root \
    /etc/grafana/grafana.ini \
    /etc/grafana/provisioning \
    /var/lib/grafana/dashboards

USER grafana