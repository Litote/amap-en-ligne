plugins {
    id("serialization-convention")
    id("ioc-convention")
    application
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    implementation(project(":service:routing"))
    implementation(project(":service:email-delivery"))
    implementation(project(":service:provisioning-gotrue"))
    implementation(project(":lib:authentication-gotrue"))
    implementation(project(":lib:instance-config-gotrue"))
    implementation(project(":lib:properties"))
    implementation(project(":persistence:postgres"))

    implementation(libs.ktor.server.cio)
    implementation(libs.ktor.server.cors)
    implementation(libs.slf4j.simple)
    implementation(libs.angus.mail)
    // FCM HTTP v1 push transport (JVM deployment only — not in the GraalVM Lambda image).
    implementation(libs.firebase.admin)

    testImplementation(libs.coroutines.test)
    testImplementation(libs.ktor.server.test.host)
    testImplementation(libs.testcontainers)
    testImplementation(libs.testcontainers.junit.jupiter)
    testImplementation(libs.testcontainers.postgres)
    // Mint GoTrue-shaped HS256 JWTs in the integration test
    testImplementation(libs.auth0.java.jwt)
}

application {
    mainClass.set("deploy.jvm.MainKt")
}

// These are heavy integration tests: each test class boots an embedded Ktor server wired to
// the *process-global* Koin context (startKoin/stopKoin in @BeforeAll/@AfterAll) plus its own
// Testcontainers Postgres. The shared kotlin-convention enables JUnit5 in-JVM parallelism
// (parallel.mode.classes.default = concurrent), which runs several such classes concurrently in
// the same JVM — they then collide on the single global Koin context
// (KoinApplicationAlreadyStartedException / ClosedScopeException) and clobber each other's DB
// truncation. Disable in-JVM JUnit parallelism here; Gradle still forks up to maxParallelForks
// JVMs (from the convention) and distributes classes across them, so cross-JVM parallelism — and
// thus speed — is preserved while each JVM runs its classes serially with an isolated Koin.
tasks.test {
    systemProperty("junit.jupiter.execution.parallel.enabled", "false")
}

val generateServiceRoleToken by tasks.registering(JavaExec::class) {
    group = "dev"
    description = "Prints a service-role JWT signed with GOTRUE_JWT_SECRET for use in GOTRUE_SERVICE_ROLE_KEY."
    mainClass.set("deploy.jvm.GenerateServiceRoleTokenKt")
    classpath = sourceSets["test"].runtimeClasspath
}

val acceptanceTest by tasks.registering(Test::class) {
    description = "Runs documented server acceptance scenarios."
    group = "verification"
    testClassesDirs = sourceSets["test"].output.classesDirs
    classpath = sourceSets["test"].runtimeClasspath
    useJUnitPlatform()
    filter {
        includeTestsMatching("deploy.jvm.AcceptanceScenariosTest")
    }
    shouldRunAfter(tasks.named("test"))
}

// NOTE: `acceptanceTest` is intentionally NOT wired into `check`. It runs only via the
// repo-root `allAcceptanceTests` aggregate (and the dedicated CI `acceptance` job), which
// keeps the fast `check` gate to unit tests and lets CI capture acceptance coverage in a
// separate job whose JaCoCo exec is merged into SonarCloud. Run `./gradlew allAcceptanceTests`
// before merging (see AGENTS.md Definition of Done).

// Load `back/deploy/jvm/.env` (when present) into the run task's environment
// so local devs can `cp .env.example .env` and `./gradlew :deploy:jvm:run`
// without having to re-export env vars on every shell.
//
// Format: `KEY=value` per line, `#` comments and blank lines are ignored.
// Surrounding single or double quotes around the value are stripped.
val dotenv = layout.projectDirectory.file(".env").asFile
tasks.named<JavaExec>("run") {
    inputs.file(dotenv).optional(true)
    doFirst {
        if (!dotenv.exists()) return@doFirst
        dotenv.readLines().forEach { raw ->
            val line = raw.trim()
            if (line.isEmpty() || line.startsWith("#")) return@forEach
            val sep = line.indexOf('=')
            if (sep <= 0) return@forEach
            val key = line.substring(0, sep).trim()
            val value =
                line
                    .substring(sep + 1)
                    .trim()
                    .removeSurrounding("\"")
                    .removeSurrounding("'")
            environment(key, value)
        }
    }
}

group = "deploy"
