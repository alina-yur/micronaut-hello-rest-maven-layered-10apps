#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COPIES_PER_APP="${COPIES_PER_APP:-1}"

source "$ROOT/scripts/app-config.sh"

validate_copies_per_app "$COPIES_PER_APP"
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

    publish_application_artifacts "$ROOT" "$image_name" "$COPIES_PER_APP"
done

echo
echo "==> Built layered Micronaut apps"
ls -lh "$ROOT/micronaut-application-layer/target"/hello-* "$ROOT/micronaut-application-layer/target/libjavabaselayer.so"
