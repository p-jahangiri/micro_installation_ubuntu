From 185.89.22.58:8082/repository/parseh-docker-private/iconify/api:latest

RUN npm config delete proxy 2>/dev/null || true
RUN npm config delete https-proxy 2>/dev/null || true

ENV HTTP_PROXY=
ENV HTTPS_PROXY=
ENV http_proxy=
ENV https_proxy=

# Set offline mode
ENV ICONIFY_SOURCE=none
ENV ALLOW_UPDATE=false

WORKDIR /data/iconify-api

# Create directories for offline use
RUN mkdir -p /data/iconify-api/icons
RUN mkdir -p /data/iconify-api/custom-icons
RUN mkdir -p /data/iconify-api/cache

CMD ["node", "--expose-gc", "lib/index.js"]