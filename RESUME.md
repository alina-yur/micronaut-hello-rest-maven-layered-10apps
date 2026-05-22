# Resume Notes

Date: 2026-05-22

Project: `/home/opc/demo-central/micronaut-hello-rest-maven-layered-10apps`

## Toolchain

```text
java version "25.0.2" 2026-01-20 LTS
Oracle GraalVM 25.1.0-dev+10.1
native-image 25.0.2
JAVA_HOME=/home/opc/.sdkman/candidates/java/current
```

## Current Status

The layered Micronaut build now works on Linux.

The upstream GraalVM Micronaut layered demo was useful. The important fix was to keep Micronaut service metadata application-layer aware while Micronaut classes live in the base layer:

```text
-H:ApplicationLayerOnlySingletons=io.micronaut.core.io.service.ServiceScanner$StaticServiceDefinitions
-H:ApplicationLayerInitializedClasses=io.micronaut.inject.annotation.AnnotationMetadataSupport
-H:ApplicationLayerInitializedClasses=io.micronaut.core.io.service.MicronautMetaServiceLoaderUtils
```

Those options are now in:

```text
base-layer/base_layer_config/META-INF/native-image/micronaut-base-layer/native-image.properties
```

The temporary `micronaut-core` `--exclude-config` workaround was removed from `base-layer/pom.xml`; the build now uses Micronaut's native-image properties directly.

## Verified

Fast Micronaut tests:

```bash
cd micronaut-application-layer
../mvnw --no-transfer-progress test
```

Result: `Tests run: 10, Failures: 0, Errors: 0, Skipped: 0`.

Base layer:

```bash
cd base-layer
../mvnw --no-transfer-progress clean install
```

Result: `BUILD SUCCESS`

Produced:

```text
base-layer/target/base-layer.nil
base-layer/target/libjavabaselayer.so
```

Focused English app-layer build:

```bash
cd micronaut-application-layer
../mvnw --no-transfer-progress \
  -Pnative -Papp-layer -Phello-app \
  -Dmaven.test.skip=true -DskipNativeTests \
  -Dhello.class=HelloEnglish \
  -Dhello.image=hello-english \
  clean package
```

Result: `BUILD SUCCESS`

Focused English smoke:

```text
/ -> Hello
/hello/english -> Hello
/hello/french -> 404
```

After the full build, the app-layer debug `--verbose` flag was removed to keep demo build output more manageable. A focused English app-layer rebuild and smoke test were rerun afterward and still passed.

All app-layer builds:

```bash
./build-all-apps.sh
```

Result: all 10 apps built successfully and were published to:

```text
micronaut-application-layer/target/hello-english
micronaut-application-layer/target/hello-french
micronaut-application-layer/target/hello-german
micronaut-application-layer/target/hello-spanish
micronaut-application-layer/target/hello-italian
micronaut-application-layer/target/hello-japanese
micronaut-application-layer/target/hello-ukrainian
micronaut-application-layer/target/hello-portuguese
micronaut-application-layer/target/hello-korean
micronaut-application-layer/target/hello-swiss
micronaut-application-layer/target/libjavabaselayer.so
```

All-app runtime smoke was run on ports `18080` through `18089`. Each app served `/` and its own `/hello/<language>` route, and returned `404` for a neighboring language route.

## Notable Local Changes

- Removed the unused `standalone` native profile from `micronaut-application-layer/pom.xml`.
- Added the provided `org.graalvm.sdk:nativeimage` dependency to `base-layer/pom.xml` so the hosted feature compiles.
- Added and retained `ReflectArrayInitialLayerFeature` handling for reflection array helpers and `java.sql` date/time classes.
- Kept `java.sql.Date`, `java.sql.Time`, and `java.sql.Timestamp` runtime initialization in both base and app layer args.
- Skipped the inherited Micronaut shade execution in the app-layer profile so the layered build uses a thin app jar plus dependency classpath.
- Added app-layer native exports required by this GraalVM layered-image setup.
- Removed the app-layer `--verbose` native-image flag after debugging; native-image still prints normal build progress, but no longer dumps the full API option expansion.
- Added app-layer compatibility reachability metadata at:

```text
micronaut-application-layer/src/main/resources/META-INF/native-image/layered-app-compat/reachability-metadata.json
```

## Remaining Notes

- Maven still reports warnings from Micronaut platform dependency management and native-image option deprecations; they did not block the build.
- `./run-all.sh` is intentionally long-running. Use it for demo/runtime memory observation; for CI-style validation, use a bounded smoke script.

No Maven or `native-image` build process should be left running.
