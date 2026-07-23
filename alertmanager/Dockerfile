FROM prom/alertmanager:v0.33.1

USER root

COPY entrypoint.sh /usr/local/bin/alertmanager-entrypoint.sh

RUN chmod 0755 /usr/local/bin/alertmanager-entrypoint.sh \
    && mkdir -p /etc/alertmanager/secrets \
    && mkdir -p /alertmanager \
    && chown -R nobody:nobody \
        /etc/alertmanager \
        /alertmanager

COPY alertmanager.yml /etc/alertmanager/alertmanager.yml

RUN chown nobody:nobody \
    /etc/alertmanager/alertmanager.yml

USER nobody

ENTRYPOINT ["/usr/local/bin/alertmanager-entrypoint.sh"]