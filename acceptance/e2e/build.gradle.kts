plugins {
    id("serialization-convention")
}

group = "e2e"

dependencies {
    testImplementation(project(":deploy:jvm"))
    testImplementation(libs.testcontainers)
    testImplementation(libs.testcontainers.junit.jupiter)
    testImplementation(libs.testcontainers.postgres)
    testImplementation(libs.auth0.java.jwt)
    testImplementation(libs.slf4j.simple)
    testImplementation(libs.ktor.server.core)
    testImplementation(libs.playwright)
}

tasks.register<JavaExec>("installPlaywrightBrowsers") {
    group = "verification"
    description = "Download Playwright Chromium browser (idempotent)."
    classpath = configurations["testRuntimeClasspath"]
    mainClass.set("com.microsoft.playwright.CLI")
    args = listOf("install", "chromium")
}

tasks.withType<Test>().configureEach {
    systemProperty("front.dir", rootProject.file("../front").absolutePath)
    maxParallelForks = 1
}

// E2e tests run only via `crossComponentTest`, never as part of regular `check`.
tasks.named("check") {
    setDependsOn(emptyList<Any>())
}
