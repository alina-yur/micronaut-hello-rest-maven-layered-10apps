#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGS_FILE="$ROOT/base-layer/base_layer_config/META-INF/native-image/micronaut-base-layer/layer-create.args"
LOG_DIR="$ROOT/.loop-logs"
MEASURE_INTERVAL="${MEASURE_INTERVAL:-15}"

mkdir -p "$LOG_DIR"

source "$ROOT/scripts/app-config.sh"
source "$ROOT/scripts/memory-lib.sh"

echo "Using ARGS_FILE=$ARGS_FILE"

run_logged_build() {
    local label="$1"
    local log_file="$2"
    local workdir="$3"
    shift 3

    (
        cd "$workdir"
        exec "$@"
    ) > >(tee "$log_file") 2>&1 &
    local build_pid=$!

    monitor_process_tree "$label" "$build_pid" "$MEASURE_INTERVAL" &
    local monitor_pid=$!

    set +e
    wait "$build_pid"
    local build_rc=$?
    set -e

    wait "$monitor_pid" 2>/dev/null || true
    return "$build_rc"
}

iteration=1

while true; do
    stamp="$(date -u +%Y%m%dT%H%M%SZ)"
    app_log="$LOG_DIR/${iteration}-app-${stamp}.log"

    echo
    echo "==> Iteration $iteration"
    build_base_layer "$ROOT"

    echo
    echo "==> Building app layer"
    set +e
    run_logged_build \
        "app-build" \
        "$app_log" \
        "$ROOT/micronaut-application-layer" \
        ../mvnw --no-transfer-progress \
        -Pnative -Papp-layer -Phello-app \
        -Dmaven.test.skip=true -DskipNativeTests \
        -Dhello.class=HelloEnglish \
        -Dhello.image=hello-english \
        package
    app_rc=$?
    set -e

    if [[ $app_rc -eq 0 ]]; then
        publish_application_artifacts "$ROOT" "hello-english"
        echo
        echo "Layered build succeeded on iteration $iteration"
        exit 0
    fi

    package_name="$(
        {
            rg -o 'Newly seen boot package package [A-Za-z0-9_.]+' "$app_log" \
            | sed 's/^Newly seen boot package package //'
            rg -o 'HotSpotType<L[A-Za-z0-9_/$.]+;' "$app_log" \
            | sed 's/^HotSpotType<L//' \
            | sed 's/;$//' \
            | tr '/' '.' \
            | sed 's/\.[^.]*$//'
        } | head -n 1 || true
    )"

    if [[ -z "$package_name" ]]; then
        echo
        echo "No new boot package was reported. Stopping for manual investigation."
        echo "Inspect: $app_log"
        exit 1
    fi

    package_line="package=$package_name"
    if rg -qxF "$package_line" "$ARGS_FILE"; then
        echo
        echo "Package $package_name was already present. Stopping to avoid a loop."
        echo "Inspect: $app_log"
        exit 1
    fi

    printf '%s\n' "$package_line" >> "$ARGS_FILE"
    echo
    echo "Added $package_line"
    iteration=$((iteration + 1))
done

