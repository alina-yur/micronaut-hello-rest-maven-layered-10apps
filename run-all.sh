#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$ROOT/micronaut-application-layer/target"
MEASURE_INTERVAL="${MEASURE_INTERVAL:-10}"

source "$ROOT/scripts/app-config.sh"
source "$ROOT/scripts/memory-lib.sh"

PIDS=()
LOG_FILES=()
BINARY_NAMES=()
CLEANED_UP=0

require_runtime_artifacts() {
    if ! command -v curl >/dev/null 2>&1; then
        echo "Missing required command: curl" >&2
        exit 1
    fi

    if [[ ! -d "$TARGET_DIR" ]]; then
        echo "Missing target directory: $TARGET_DIR" >&2
        echo "Build the layered apps first with ./build-all-apps.sh" >&2
        exit 1
    fi

    if [[ ! -f "$TARGET_DIR/libjavabaselayer.so" ]]; then
        echo "Missing shared base layer: $TARGET_DIR/libjavabaselayer.so" >&2
        echo "Build the layered apps first with ./build-all-apps.sh" >&2
        exit 1
    fi

    for app in "${LANGUAGES[@]}"; do
        binary_name="$(image_name_for_app "$app")"
        if [[ ! -x "$TARGET_DIR/$binary_name" ]]; then
            echo "Missing layered app binary: $TARGET_DIR/$binary_name" >&2
            echo "Build the layered apps first with ./build-all-apps.sh" >&2
            exit 1
        fi
    done
}

cleanup() {
    if [[ "$CLEANED_UP" -eq 1 ]]; then
        return
    fi
    CLEANED_UP=1

    echo
    echo "Stopping all apps..."
    for pid in "${PIDS[@]:-}"; do
        kill "$pid" 2>/dev/null || true
    done
    for pid in "${PIDS[@]:-}"; do
        wait "$pid" 2>/dev/null || true
    done
    for log_file in "${LOG_FILES[@]:-}"; do
        rm -f "$log_file"
    done
}

trap cleanup EXIT INT TERM

require_runtime_artifacts

export LD_LIBRARY_PATH="$TARGET_DIR:${LD_LIBRARY_PATH:-}"

echo "=== Starting 10 Micronaut app instances sharing libjavabaselayer.so ==="
echo

for i in "${!LANGUAGES[@]}"; do
    lang="${LANGUAGES[$i]}"
    port="${PORTS[$i]}"
    binary_name="$(image_name_for_app "$lang")"
    log_file="$(mktemp)"

    "$TARGET_DIR/$binary_name" "--micronaut.server.port=$port" >"$log_file" 2>&1 &
    pid=$!

    PIDS+=("$pid")
    LOG_FILES+=("$log_file")
    BINARY_NAMES+=("$binary_name")
    echo "  Started $binary_name on port $port (PID $pid)"
done

echo
echo "Waiting for all endpoints to come up..."
for i in "${!LANGUAGES[@]}"; do
    lang="${LANGUAGES[$i]}"
    port="${PORTS[$i]}"
    ok=0

    for _ in {1..60}; do
        if curl -fsS "http://127.0.0.1:$port/hello/$lang" >/dev/null 2>&1; then
            ok=1
            break
        fi
        sleep 1
    done

    if [[ "$ok" -ne 1 ]]; then
        echo "ERROR: hello-$lang on port $port did not start cleanly." >&2
        tail -n 40 "${LOG_FILES[$i]}" >&2 || true
        exit 1
    fi
done

echo
echo "All 10 app instances are running. Endpoints:"
for i in "${!LANGUAGES[@]}"; do
    lang="${LANGUAGES[$i]}"
    port="${PORTS[$i]}"
    echo "  curl http://127.0.0.1:$port/hello/$lang"
done

echo
echo "Memory usage:"

while true; do
    total_rss=0
    total_uss=0
    total_pss=0

    printf "  %-16s %8s %8s %8s %s\n" "APP" "RSS" "USS" "PSS" "PID"
    for i in "${!PIDS[@]}"; do
        pid="${PIDS[$i]}"
        binary_name="${BINARY_NAMES[$i]}"

        if kill -0 "$pid" 2>/dev/null; then
            read -r rss uss pss < <(tree_memory_kb "$pid")
            printf "  %-16s %5s KB %5s KB %5s KB  (PID %s)\n" "$binary_name" "$rss" "$uss" "$pss" "$pid"
            total_rss=$((total_rss + rss))
            total_uss=$((total_uss + uss))
            total_pss=$((total_pss + pss))
        else
            printf "  %-16s %8s %8s %8s  (%s)\n" "$binary_name" "dead" "dead" "dead" "$pid"
        fi
    done

    printf "  %-16s %5s KB %5s KB %5s KB\n" "TOTAL" "$total_rss" "$total_uss" "$total_pss"
    echo
    sleep "$MEASURE_INTERVAL"
done
