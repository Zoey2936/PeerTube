FROM nginx:alpine

COPY support/docker/production/entrypoint.nginx.sh /usr/local/bin/entrypoint.nginx.sh
RUN apk add --no-cache ca-certificates tzdata tini && \
    chmod +x /usr/local/bin/entrypoint.nginx.sh

ENTRYPOINT ["tini", "--"]
CMD ["entrypoint.nginx.sh"]
