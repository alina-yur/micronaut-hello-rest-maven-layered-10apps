#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT/scripts/app-config.sh"

TARGET_DIR="$ROOT/micronaut-application-layer/target"
OUTPUT_DIR="$TARGET_DIR/standalone"

mkdir -p "$OUTPUT_DIR"

for app in "${LANGUAGES[@]}"; do
    hello_class="$(hello_class_for_app "$app")"
    image_name="$(image_name_for_app "$app")"
    build_dir="$TARGET_DIR/${image_name}-build"

    echo
    echo "==> Building standalone $image_name"
    (
        cd "$ROOT/micronaut-application-layer"
        ../mvnw --no-transfer-progress \
            -Pnative -Pstandalone -Phello-app \
            -Dmaven.test.skip=true -DskipNativeTests \
            -Dhello.class="$hello_class" \
            -Dhello.image="$image_name" \
            clean package
    )

    cp "$build_dir/$image_name" "$OUTPUT_DIR/$image_name"
done

echo
echo "==> Built standalone Micronaut apps"
ls -lh "$OUTPUT_DIR"/hello-*
