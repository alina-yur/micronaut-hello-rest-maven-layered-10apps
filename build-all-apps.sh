#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT/scripts/app-config.sh"

ensure_base_layer_target "$ROOT"

for app in "${LANGUAGES[@]}"; do
    hello_class="$(hello_class_for_app "$app")"
    image_name="$(image_name_for_app "$app")"

    echo
    echo "==> Building $image_name"
    (
        cd "$ROOT/micronaut-application-layer"
        ../mvnw --no-transfer-progress \
            -Pnative -Papp-layer -Phello-app \
            -Dmaven.test.skip=true -DskipNativeTests \
            -Dhello.class="$hello_class" \
            -Dhello.image="$image_name" \
            package
    )

    publish_application_artifacts "$ROOT" "$image_name"
done

echo
echo "==> Built layered Micronaut apps"
ls -lh "$ROOT/micronaut-application-layer/target"/hello-* "$ROOT/micronaut-application-layer/target/libjavabaselayer.so"

