import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.time.Duration

plugins {
    id("project-convention")
    kotlin("jvm")
    id("jacoco")
}

plugin("ktlint")

dependencies {
    constraints {
        implementation(lib("kotlin-reflect"))
    }
    implementation(lib("logging"))
    testImplementation(kotlin("test"))
    testImplementation(lib("mockk"))
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_25)
        freeCompilerArgs.addAll("-Xjdk-release=25", "-Xconsistent-data-class-copy-visibility")
    }
}

java {
    sourceCompatibility = JavaVersion.VERSION_25
    targetCompatibility = JavaVersion.VERSION_25
}

tasks.test {
    useJUnitPlatform()
    failOnNoDiscoveredTests = false
    systemProperty("junit.jupiter.execution.parallel.enabled", "true")
    systemProperty("junit.jupiter.execution.parallel.mode.default", "concurrent")
    systemProperty("junit.jupiter.execution.parallel.mode.classes.default", "concurrent")

    maxParallelForks = Runtime.getRuntime().availableProcessors()

    // Backstop, not the primary defense: DynamoClient now sets an explicit connectTimeout/
    // connectionAcquireTimeout (persistence/dynamo/src/main/kotlin/DynamoClient.kt) so an
    // unreachable DynamoDB-Local fails in seconds. But CrtHttpEngine does not support a
    // read/write timeout (see its own commented-out warning in aws.smithy.kotlin) — a
    // container that accepts the connection but never answers can still hang a test with no
    // client-side deadline (observed: a 6h CI hang on `:persistence:dynamo:test`). This
    // per-task deadline kills the forked worker and reports a clear failure naming the
    // module. 10 min is ~5x the slowest legitimate test task.
    timeout.set(Duration.ofMinutes(10))

    finalizedBy(tasks.jacocoTestReport)
}

tasks.jacocoTestReport {
    dependsOn(tasks.test)
    reports {
        xml.required.set(true)
        html.required.set(false)
    }
}

tasks.withType<Jar>().configureEach {
    isPreserveFileTimestamps = false
    isReproducibleFileOrder = true
}

