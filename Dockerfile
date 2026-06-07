FROM rust:1-slim AS rathole-build
ARG RATHOLE_REPO=https://github.com/rathole-org/rathole.git
ARG RATHOLE_REF=main

RUN apt-get update \
 && apt-get install -y --no-install-recommends git pkg-config libssl-dev ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN git clone "${RATHOLE_REPO}" /src \
 && cd /src && git checkout "${RATHOLE_REF}" \
 && cargo build --release \
 && strip target/release/rathole

FROM vllm/vllm-openai:latest

RUN apt-get update \
 && apt-get install -y --no-install-recommends gettext-base ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY --from=rathole-build /src/target/release/rathole /usr/local/bin/rathole
RUN chmod +x /usr/local/bin/rathole && /usr/local/bin/rathole --help >/dev/null

COPY rathole-client.toml.template /opt/rathole/client.toml.template
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV VLLM_PORT=8000 \
    RATHOLE_SERVICE=vllm

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
