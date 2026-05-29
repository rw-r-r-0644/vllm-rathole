FROM vllm/vllm-openai:latest

ARG RATHOLE_VERSION=v0.5.0
ARG RATHOLE_ARCH=x86_64-unknown-linux-gnu

RUN apt-get update \
 && apt-get install -y --no-install-recommends gettext-base unzip curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/rathole.zip \
      "https://github.com/rathole-org/rathole/releases/download/${RATHOLE_VERSION}/rathole-${RATHOLE_ARCH}.zip" \
 && unzip /tmp/rathole.zip -d /usr/local/bin/ \
 && chmod +x /usr/local/bin/rathole \
 && rm /tmp/rathole.zip \
 && /usr/local/bin/rathole --help >/dev/null

RUN mkdir -p /etc/rathole
COPY rathole-client.toml.template /etc/rathole/client.toml.template
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV VLLM_PORT=8000 \
    RATHOLE_SERVICE=vllm \
    VLLM_ARGS=""

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
