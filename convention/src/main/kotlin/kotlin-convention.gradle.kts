import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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

