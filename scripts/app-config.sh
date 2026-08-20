#!/usr/bin/env bash

LANGUAGES=(
  english
  french
  german
  spanish
  italian
  japanese
  ukrainian
  portuguese
  korean
  swiss
)

HELLO_CLASSES=(
  HelloEnglish
  HelloFrench
  HelloGerman
  HelloSpanish
  HelloItalian
  HelloJapanese
  HelloUkrainian
  HelloPortuguese
  HelloKorean
  HelloSwiss
)

IMAGE_NAMES=(
  hello-english
  hello-french
  hello-german
  hello-spanish
  hello-italian
  hello-japanese
  hello-ukrainian
  hello-portuguese
  hello-korean
  hello-swiss
)

PORTS=(8080 8081 8082 8083 8084 8085 8086 8087 8088 8089)

app_index() {
    local app="$1"
    local i
    for i in "${!LANGUAGES[@]}"; do
        if [[ "${LANGUAGES[$i]}" == "$app" ]]; then
            echo "$i"
            return 0
        fi
    done

    echo "Unsupported APP=$app" >&2
    echo "Supported values: ${LANGUAGES[*]}" >&2
    return 1
}

hello_class_for_app() {
    local index
    index="$(app_index "$1")" || return 1
    echo "${HELLO_CLASSES[$index]}"
}

image_name_for_app() {
    local index
    index="$(app_index "$1")" || return 1
    echo "${IMAGE_NAMES[$index]}"
}

port_for_app() {
    local index
    index="$(app_index "$1")" || return 1
    echo "${PORTS[$index]}"
}

build_base_layer() {
    local root="$1"

    echo "==> Building Micronaut base layer"
    (
        cd "$root/base-layer"
        ../mvnw --no-transfer-progress clean install
    )
}

ensure_base_layer_target() {
    local root="$1"
    local local_target="$root/base-layer/target"

    if [[ -f "$local_target/base-layer.nil" && -f "$local_target/libjavabaselayer.so" ]]; then
        return 0
    fi

    build_base_layer "$root"
}

publish_application_artifacts() {
    local root="$1"
    local image_name="$2"
    local app_target="$root/micronaut-application-layer/target"
    local work_dir="$app_target/$image_name-build"

    mkdir -p "$app_target"
    cp "$work_dir/$image_name" "$app_target/$image_name"
    cp "$root/base-layer/target/libjavabaselayer.so" "$app_target/libjavabaselayer.so"
}
