# Install manually client dependencies to apply our network timeout option
FROM --platform="$BUILDPLATFORM" node:21.7.2-alpine as build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
COPY . /app
ARG TARGETARCH
WORKDIR /app
RUN apk add --no-cache ca-certificates bash && \
    if [ "$TARGETARCH" = "amd64" ]; then \
      cd /app/client && \
      npm_config_target_platform=linux npm_config_target_arch=x64 yarn install --pure-lockfile --network-timeout 1200000 && \
      cd /app && \
      npm_config_target_platform=linux npm_config_target_arch=x64 yarn install --network-timeout 1200000 && \
      npm_config_target_platform=linux npm_config_target_arch=x64 npm run build && \
      rm -r /app/client/node_modules /app/node_modules /app/client/.angular && \
      npm_config_target_platform=linux npm_config_target_arch=x64 yarn install --pure-lockfile --production --network-timeout 1200000 --network-concurrency 20; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      cd /app/client && \
      npm_config_target_platform=linux npm_config_target_arch=arm64 yarn install --pure-lockfile --network-timeout 1200000 && \
      cd /app && \
      npm_config_target_platform=linux npm_config_target_arch=arm64 yarn install --network-timeout 1200000 && \
      npm_config_target_platform=linux npm_config_target_arch=arm64 npm run build && \
      rm -r /app/client/node_modules /app/node_modules /app/client/.angular && \
      npm_config_target_platform=linux npm_config_target_arch=arm64 yarn install --pure-lockfile --production --network-timeout 1200000 --network-concurrency 20; \
    fi && \
    yarn cache clean --all

FROM node:21.7.2-alpine
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
COPY --from=build /app /app
WORKDIR /app

# Install dependencies
RUN apk add --no-cache ca-certificates tzdata tini ffmpeg su-exec shadow && \
# Add peertube user
    groupadd -r peertube && \
    useradd -r -g peertube -m peertube && \
# script, folder, permissions and cleanup
    mv /app/support/docker/production/entrypoint.sh /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh && \
    mkdir /data /config && \
    chown -R peertube:peertube /app /data /config && \
    apk del --no-cache shadow

ENV NODE_ENV=production
ENV NODE_CONFIG_DIR=/app/config:/app/support/docker/production/config:/config
ENV PEERTUBE_LOCAL_CONFIG=/config

ENTRYPOINT ["tini", "--", "entrypoint.sh"]
CMD ["node", "dist/server"]
