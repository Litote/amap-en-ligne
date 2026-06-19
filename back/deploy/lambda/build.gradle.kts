plugins {
    id("ioc-convention")
    id("serialization-convention")
    alias(libs.plugins.graalvm.native)
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    implementation(project(":service:core"))
    implementation(project(":persistence:dynamo"))
    implementation(project(":lib:lambda"))
    implementation(project(":lib:lambda-ktor"))
    implementation(project(":lib:authentication-cognito"))
    implementation(project(":lib:instance-config-cognito"))
    implementation(project(":service:routing"))
    implementation(project(":service:email-delivery"))
    implementation(project(":service:provisioning-cognito"))
    implementation(libs.asyncant.lambda.runtime.jvm)
    implementation(libs.aws.sns)
    implementation(libs.aws.ses)
    implementation(libs.aws.smithy.http.client.engine.crt)

    testImplementation(project(":lib:instance-config-gotrue"))
}

configurations.all {
    // okhttp HTTP engines — replaced by CrtHttpEngine
    exclude(group = "aws.smithy.kotlin", module = "http-client-engine-okhttp")
    exclude(group = "aws.smithy.kotlin", module = "http-client-engine-okhttp-jvm")
    exclude(group = "com.squareup.okhttp3", module = "okhttp")
    exclude(group = "com.squareup.okhttp3", module = "okhttp-jvm")
    exclude(group = "com.squareup.okhttp3", module = "okhttp-coroutines")
    exclude(group = "com.squareup.okhttp3", module = "okhttp-coroutines-jvm")

    // Ktor — opt-in features unused on Lambda
    exclude(group = "io.ktor", module = "ktor-websockets")
    exclude(group = "io.ktor", module = "ktor-websockets-jvm")

    // Cosmetic — CloudWatch strips ANSI anyway
    exclude(group = "org.fusesource.jansi", module = "jansi")

    // HOCON config — using programmatic embeddedServer, no application.conf
    exclude(group = "com.typesafe", module = "config")

    // SNS uses Form URL for requests but XML for responses (AWS Query protocol) — keep serde-xml
    // serde-form-url is required by the SNS SDK (Publish operation uses Form URL encoding)
}

graalvmNative {
    binaries {
        named("main") {
            imageName.set("bootstrap")
            mainClass.set("deploy.lambda.MainKt")
            buildArgs.addAll(
                "--initialize-at-build-time=io.github.oshai.kotlinlogging,org.koin",
                "--enable-native-access=ALL-UNNAMED",
                "--enable-url-protocols=https,http",
                "--no-fallback",
                "-H:+ReportExceptionStackTraces",
            )
        }
        create("tracing") {
            imageName.set("tracing-runner")
            mainClass.set("deploy.lambda.TracingRunnerKt")
            classpath(sourceSets["main"].runtimeClasspath)
            buildArgs.addAll(
                "--enable-native-access=ALL-UNNAMED",
                "--no-fallback",
                "-H:+InstallExitHandlers",
                "-H:+ReportUnsupportedElementsAtRuntime",
                "-H:+ReportExceptionStackTraces",
            )
        }
    }
    metadataRepository {
        enabled.set(true)
        version.set("1.0.0")
    }
    agent {
        defaultMode.set("standard")
        metadataCopy {
            inputTaskNames.add("tracing")
            outputDirectories.add("src/main/resources/META-INF/native-image")
            mergeWithExisting.set(true)
        }
    }
}

val tracing by tasks.registering(JavaExec::class) {
    group = "graalvm"
    description = "Run the handler with native-image-agent to record reflection/serialization metadata (use -Pagent)."
    mainClass.set("deploy.lambda.TracingRunnerKt")
    classpath = sourceSets["main"].runtimeClasspath
    environment("APP_MODE", "local")
    // DYNAMO_LOCAL_ENDPOINT must be declared via providers so Gradle's
    // configuration cache tracks it; otherwise a value set in the parent
    // env at run time is not forwarded to the JavaExec'd JVM after the
    // first cache hit (cf. host.docker.internal usage from `make trace`).
    providers.environmentVariable("DYNAMO_LOCAL_ENDPOINT").orNull?.let {
        environment("DYNAMO_LOCAL_ENDPOINT", it)
    }
}

val packageNative by tasks.registering(Zip::class) {
    dependsOn("nativeCompile")
    archiveFileName.set("lambda.zip")
    destinationDirectory.set(layout.buildDirectory.dir("libs"))
    from(layout.buildDirectory.dir("native/nativeCompile")) {
        include("bootstrap")
        include("libaws-crt-jni.so")
        filePermissions { unix("755") }
    }
}

tasks.build { dependsOn(packageNative) }

group = "deploy"
