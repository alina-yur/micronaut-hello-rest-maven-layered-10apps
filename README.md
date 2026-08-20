# Micronaut Layered Native Image Demo

This project mirrors the Spring layered demo, but uses Micronaut. It builds 10 small HTTP applications on top of one shared GraalVM Native Image base layer.

The layout intentionally follows the original:

```text
base-layer/                  # builds base-layer.nil and libjavabaselayer.so
micronaut-application-layer/  # builds one native executable per language
scripts/                     # shared app and memory helpers
build-all-apps.sh
build-all-standalone.sh
run.sh
run-all.sh
run-all-standalone.sh
```

Each executable exposes `/` and its own `/hello/<language>` endpoint:

```text
hello-english      /hello/english      Hello       port 8080
hello-french       /hello/french       Bonjour     port 8081
hello-german       /hello/german       Hallo       port 8082
hello-spanish      /hello/spanish      Hola        port 8083
hello-italian      /hello/italian      Ciao        port 8084
hello-japanese     /hello/japanese     こんにちは   port 8085
hello-ukrainian    /hello/ukrainian    Привіт      port 8086
hello-portuguese   /hello/portuguese   Olá         port 8087
hello-korean       /hello/korean       안녕하세요   port 8088
hello-swiss        /hello/swiss        Grüezi      port 8089
```

## Prerequisites

- Linux x64
- GraalVM JDK 25.1 EA or newer with `native-image`
- `JAVA_HOME` pointing at that GraalVM

Native Image Layers are Linux-only in this setup. The Maven compile/test path works on macOS, but the layered native builds should be run on Linux.

## Build

Build the shared base layer plus all 10 app binaries:

```bash
./build-all-apps.sh
```

This first runs `mvn clean install` in `base-layer`, producing:

```text
base-layer/target/base-layer.nil
base-layer/target/libjavabaselayer.so
```

Then it builds each Micronaut application layer with:

```bash
../mvnw --no-transfer-progress \
  -Pnative -Papp-layer -Phello-app \
  -Dmaven.test.skip=true -DskipNativeTests \
  -Dhello.class=HelloEnglish \
  -Dhello.image=hello-english \
  package
```

The `hello-app` profile compiles exactly one language controller into an isolated build directory. This is important for Micronaut because its annotation processor writes controller bean metadata at compile time. If all 10 controllers were compiled into every app, every binary would contain every route.

Final runtime artifacts are copied to:

```text
micronaut-application-layer/target/libjavabaselayer.so
micronaut-application-layer/target/hello-english
micronaut-application-layer/target/hello-french
...
```

## Standalone Comparison

Build one non-layered standalone native Micronaut executable per language:

```bash
./build-all-standalone.sh
```

The 10 executables are written to `micronaut-application-layer/target/standalone/`.

Run the 10 language-specific standalone executables and measure their combined
RSS/USS/PSS usage. Build them first with `./build-all-standalone.sh`:

```bash
./run-all-standalone.sh
```

Standalone instances use ports `8180` through `8189`, so both this runner and
`./run-all.sh` can be used at the same time. Set `PORT_BASE` to choose another
starting port, or set `MEASURE_INTERVAL` to change the measurement interval.

## Run One App

English on its default port:

```bash
./run.sh
```

Another language:

```bash
APP=japanese ./run.sh
```

Custom port:

```bash
APP=swiss PORT=8090 ./run.sh
```

The script prints RSS/USS/PSS samples while the app is running.

## Run All Apps

```bash
./run-all.sh
```

This starts all 10 executables, waits for their endpoints, and prints live RSS/USS/PSS totals.

## Verify

```bash
curl http://127.0.0.1:8080/hello/english
curl http://127.0.0.1:8081/hello/french
curl http://127.0.0.1:8082/hello/german
curl http://127.0.0.1:8083/hello/spanish
curl http://127.0.0.1:8084/hello/italian
curl http://127.0.0.1:8085/hello/japanese
curl http://127.0.0.1:8086/hello/ukrainian
curl http://127.0.0.1:8087/hello/portuguese
curl http://127.0.0.1:8088/hello/korean
curl http://127.0.0.1:8089/hello/swiss
```

## Local Non-Layer Checks

These do not require Linux layers:

```bash
cd micronaut-application-layer
../mvnw test
```

The test path directly verifies all 10 greeting classes without starting a Micronaut context.
