#!/usr/bin/env bash
set -uo pipefail

: "${VLLM_PORT:?VLLM_PORT must be set}"
: "${RATHOLE_REMOTE:?RATHOLE_REMOTE must be set}"
: "${RATHOLE_LOCAL_PRIVKEY:?RATHOLE_LOCAL_PRIVKEY must be set}"
: "${RATHOLE_REMOTE_PUBKEY:?RATHOLE_REMOTE_PUBKEY must be set}"
: "${RATHOLE_SERVICE:?RATHOLE_SERVICE must be set}"
: "${RATHOLE_SERVICE_TOKEN:?RATHOLE_SERVICE_TOKEN must be set}"

RATHOLE_TEMPLATE="${RATHOLE_TEMPLATE:-/opt/rathole/client.toml.template}"
RATHOLE_RUNTIME_DIR="${RATHOLE_RUNTIME_DIR:-${TMPDIR:-/tmp}/rathole}"
mkdir -p "$RATHOLE_RUNTIME_DIR"
RATHOLE_CONFIG="$RATHOLE_RUNTIME_DIR/client.toml"
export VLLM_PORT RATHOLE_REMOTE RATHOLE_LOCAL_PRIVKEY RATHOLE_REMOTE_PUBKEY RATHOLE_SERVICE RATHOLE_SERVICE_TOKEN
envsubst < "$RATHOLE_TEMPLATE" > "$RATHOLE_CONFIG"

rathole_supervisor() {
  while true; do
    echo "[rathole-supervisor] starting rathole" >&2
    /usr/local/bin/rathole "$RATHOLE_CONFIG"
    rc=$?
    echo "[rathole-supervisor] rathole exited rc=$rc, restarting in 2s" >&2
    sleep 2
  done
}

rathole_supervisor &
RATHOLE_PID=$!

# Word-split VLLM_ARGS with shell-quoting support so operators can pass
# whitespace-bearing values via quoting in the env var.
eval "set -- ${VLLM_ARGS:-}"

vllm serve --host 127.0.0.1 --port "${VLLM_PORT}" "$@" &
VLLM_PID=$!

shutdown() {
  trap - TERM INT
  kill -TERM "$VLLM_PID" "$RATHOLE_PID" 2>/dev/null || true
  wait "$VLLM_PID" 2>/dev/null || true
  exit 0
}
trap shutdown TERM INT

wait "$VLLM_PID"
VLLM_RC=$?
kill -TERM "$RATHOLE_PID" 2>/dev/null || true
exit "$VLLM_RC"
