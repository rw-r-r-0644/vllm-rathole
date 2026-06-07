# vllm-rathole

vllm + rathole noise client in one container.
image: `ghcr.io/rw-r-r-0644/vllm-rathole`.

## env

required:
- `RATHOLE_REMOTE` — rathole server `host:port`
- `RATHOLE_LOCAL_PRIVKEY` — noise client private key
- `RATHOLE_REMOTE_PUBKEY` — noise server public key
- `RATHOLE_SERVICE_TOKEN`

optional:
- `VLLM_PORT` (default `8000`)
- `RATHOLE_SERVICE` (default `vllm`)
- `VLLM_CONFIG` — path to a mounted [vLLM YAML config file](https://docs.vllm.ai/en/latest/configuration/serve_args.html), passed to `vllm serve` as `--config`
- `RATHOLE_RUNTIME_DIR` — where the rendered rathole config is written (default `${TMPDIR:-/tmp}/rathole`); only needs changing if `/tmp` isn't writable

## run

    docker run --gpus all --ipc=host \
      -e RATHOLE_REMOTE=server:2333 \
      -e RATHOLE_LOCAL_PRIVKEY=... \
      -e RATHOLE_REMOTE_PUBKEY=... \
      -e RATHOLE_SERVICE_TOKEN=... \
      -e VLLM_CONFIG=/etc/vllm/config.yaml \
      -v "$PWD/config.yaml:/etc/vllm/config.yaml:ro" \
      ghcr.io/rw-r-r-0644/vllm-rathole

vllm runs in the foreground, rathole is supervised in the background and restarts on exit.
