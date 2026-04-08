FROM discourse/base:release

ARG DISCOURSE_DIR=/var/www/discourse

WORKDIR ${DISCOURSE_DIR}

COPY . ${DISCOURSE_DIR}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bootstrap /usr/local/bin/bootstrap
COPY start-discourse.sh /usr/local/bin/start-discourse.sh

RUN chmod +x \
    /usr/local/bin/entrypoint.sh \
    /usr/local/bin/bootstrap \
    /usr/local/bin/start-discourse.sh

RUN mkdir -p \
    /shared/log/rails \
    /shared/tmp \
    /shared/uploads \
    /shared/backups \
    tmp/pids

RUN rm -f tmp/pids/server.pid

RUN bundle config set without 'development test' && \
    bundle install -j "$(nproc)" --retry 3

RUN if [ -f yarn.lock ]; then yarn install --frozen-lockfile; fi

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/start-discourse.sh"]
