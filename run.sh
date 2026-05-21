#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${APP:-english}"
BUILD_MODE="${BUILD_MODE:-if-needed}"
MEASURE_MEMORY="${MEASURE_MEMORY:-1}"
MEASURE_INTERVAL="${MEASURE_INTERVAL:-10}"

source "$ROOT/scripts/app-config.sh"
source "$ROOT/scripts/memory-lib.sh"

HELLO_CLASS="$(hello_class_for_app "$APP")"
IMAGE_NAME="$(image_name_for_app "$APP")"
DEFAULT_PORT="$(port_for_app "$APP")"
PORT="${PORT:-$DEFAULT_PORT}"
TARGET_DIR="$ROOT/micronaut-application-layer/target"
BINARY="$TARGET_DIR/$IMAGE_NAME"

build_app() {
    ensure_base_layer_target "$ROOT"

    echo
    echo "==> Building app layer"
    (
        cd "$ROOT/micronaut-application-layer"
        ../mvnw --no-transfer-progress \
            -Pnative -Papp-layer -Phello-app \
            -Dmaven.test.skip=true -DskipNativeTests \
            -Dhello.class="$HELLO_CLASS" \
            -Dhello.image="$IMAGE_NAME" \
            package
    )

    publish_application_artifacts "$ROOT" "$IMAGE_NAME"
}

case "$BUILD_MODE" in
    always)
        build_app
        ;;
    if-needed)
        if [[ ! -x "$BINARY" ]]; then
            build_app
        fi
        ;;
    never)
        ;;
    *)
        echo "Unsupported BUILD_MODE=$BUILD_MODE (use always, if-needed, or never)" >&2
        exit 1
        ;;
esac

if [[ ! -x "$BINARY" ]]; then
    echo "Missing binary: $BINARY" >&2
    exit 1
fi

app_pid=""

cleanup() {
    if [[ -n "$app_pid" ]] && kill -0 "$app_pid" 2>/dev/null; then
        kill "$app_pid" 2>/dev/null || true
        wait "$app_pid" 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

export LD_LIBRARY_PATH="$TARGET_DIR:${LD_LIBRARY_PATH:-}"

echo
echo "==> Starting $IMAGE_NAME on port $PORT"
echo "==> Try: curl http://127.0.0.1:$PORT/hello/$APP"
"$BINARY" "--micronaut.server.port=$PORT" &
app_pid=$!

if [[ "$MEASURE_MEMORY" == "1" ]]; then
    echo
    echo "==> RSS/PSS measurements every ${MEASURE_INTERVAL}s"
    monitor_process_tree "$IMAGE_NAME" "$app_pid" "$MEASURE_INTERVAL"
else
    wait "$app_pid"
fi

