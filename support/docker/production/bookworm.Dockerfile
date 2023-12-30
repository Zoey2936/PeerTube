# Install manually client dependencies to apply our network timeout option
FROM --platform="$BUILDPLATFORM" node:18-bookworm-slim as build
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
COPY . /app
ARG TARGETARCH
WORKDIR /app
RUN apt update && \
    apt install -y --no-install-recommends openssl ffmpeg python3 ca-certificates gnupg build-essential curl git && \
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

FROM node:18-bookworm-slim
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
COPY --from=build /app /app
WORKDIR /app

# Install dependencies
RUN apt update && \
    apt install -y --no-install-recommends openssl ffmpeg python3 ca-certificates gnupg build-essential curl git tini && \
    rm /var/lib/apt/lists/* -fR && \
# Add peertube user
    groupadd -r peertube && \
    useradd -r -g peertube -m peertube && \
# script, folder and permissions
    mv /app/support/docker/production/entrypoint.sh /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh && \
    mkdir /data /config && \
    chown -R peertube:peertube /app /data /config

ENV NODE_ENV=production
ENV NODE_CONFIG_DIR=/app/config:/app/support/docker/production/config:/config
ENV PEERTUBE_LOCAL_CONFIG=/config

ENTRYPOINT ["tini", "--", "entrypoint.sh"]
CMD ["node", "dist/server"]
