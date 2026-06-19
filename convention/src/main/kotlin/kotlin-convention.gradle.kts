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

    // Fail fast instead of hanging the whole build forever. Some tests block on external
    // resources without a timeout — e.g. the DynamoDB-Local-backed DAO tests issue AWS CRT
    // calls and await `CompletableFuture.get()` with no deadline, so an unreachable local
    // container in CI makes the `test` task never return (observed: a 6h CI hang on
    // `:persistence:dynamo:test`). This per-task deadline kills the forked worker and reports
    // a clear failure naming the module. 10 min is ~5x the slowest legitimate test task.
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

