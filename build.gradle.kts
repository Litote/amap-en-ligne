plugins {
    id("project-convention")
    alias(libs.plugins.version.catalog.update)
    alias(libs.plugins.ktlint) apply false
    id("jacoco")
}

fun includedTask(
    buildName: String,
    taskPath: String,
) = gradle.includedBuilds.first { it.name == buildName }.task(taskPath)

tasks.register("check") {
    gradle.includedBuilds.forEach { included ->
        dependsOn(included.task(":check"))
    }
}

tasks.register("format") {
    gradle.includedBuilds.forEach { included ->
        if(included.name != "convention") {
            dependsOn(included.task(":format"))
        }
    }
}

tasks.register("lint") {
    gradle.includedBuilds.forEach { included ->
        if(included.name != "convention") {
            dependsOn(included.task(":lint"))
        }
    }
}

tasks.register("acceptanceTest") {
    dependsOn(
        includedTask("back", ":acceptanceTest"),
        includedTask("front", ":frontAcceptanceTest"),
    )
}

tasks.register("crossComponentTest") {
    description = "Runs cross-component e2e tests via Kotlin E2E tests (requires Docker and flutter in PATH)."
    group = "verification"
    dependsOn(includedTask("back", ":crossComponentTest"))
    // Note: Flutter cross-component tests are launched by back/:crossComponentTest (via :e2e:test)
    // with proper Docker containers and environment variables. Do NOT run frontCrossComponentTest
    // independently — it will fail without the E2E environment.
}

tasks.register("allAcceptanceTests") {
    description = "Runs all acceptance tests: back acceptance + flutter acceptance + cross-component E2E tests. MUST be run before merging any feature or bug fix."
    group = "verification"
    dependsOn(
        "acceptanceTest",
        "crossComponentTest",
    )
}

// Coverage inputs first, then analysis, then gate enforcement.
// `jacocoAggregatedReport` runs back unit + acceptance tests and folds in any present
// e2e exec; CI instead splits coverage across dedicated jobs (see .github/workflows/ci.yml).
//
// Gradle offers NO ordering primitive across included builds: dependsOn imposes no
// order and mustRunAfter/finalizedBy reject tasks from another build. Running the
// four tasks in one graph therefore lets the scan read the coverage files left by
// the PREVIOUS run (stale lcov/jacoco), silently under-reporting coverage. The scan
// + gate phase thus runs as a nested Gradle invocation strictly after the coverage
// phase; `:back:sonarCheck` orders itself after `:sonar` inside the back build.
val sonarCoverage = tasks.register("sonarCoverage") {
    description = "Generates back (unit + acceptance) + front coverage for the SonarCloud scan."
    group = "verification"
    dependsOn(
        includedTask("back", ":jacocoAggregatedReport"),
        includedTask("front", ":frontTest"),
    )
}

tasks.register("sonarScanAndGate") {
    description = "Uploads the already-generated coverage to SonarCloud, then enforces the quality gate."
    group = "verification"
    dependsOn(
        includedTask("back", ":sonar"),
        includedTask("back", ":sonarCheck"),
    )
}

tasks.register("allSonar") {
    description = "Generates back (unit + acceptance) + front coverage, uploads to SonarCloud, then enforces the quality gate."
    group = "verification"
    dependsOn(sonarCoverage)
    notCompatibleWithConfigurationCache("launches a nested Gradle invocation")
    val gradlew = File(rootDir, if (System.getProperty("os.name").startsWith("Windows")) "gradlew.bat" else "gradlew").absolutePath
    val workDir = rootDir
    doLast {
        val process = ProcessBuilder(gradlew, "sonarScanAndGate", "--no-configuration-cache")
            .directory(workDir)
            .inheritIO()
            .start()
        check(process.waitFor() == 0) { "SonarCloud scan or quality gate failed (see output above)" }
    }
}

tasks.register("frontAnalyze") {
    dependsOn(includedTask("front", ":frontAnalyze"))
}

tasks.register("frontTest") {
    dependsOn(includedTask("front", ":frontTest"))
}

tasks.register("frontAcceptanceTest") {
    dependsOn(includedTask("front", ":frontAcceptanceTest"))
}

tasks.register("frontCrossComponentTest") {
    description = "Runs Flutter cross-component acceptance tests (individually skipped when env vars absent)."
    group = "verification"
    dependsOn(includedTask("front", ":frontCrossComponentTest"))
}

tasks.register("frontBuildAndroid") {
    dependsOn(includedTask("front", ":frontBuildAndroid"))
}

tasks.register("frontBuildIos") {
    dependsOn(includedTask("front", ":frontBuildIos"))
}

tasks.register("frontBuildWeb") {
    dependsOn(includedTask("front", ":frontBuildWeb"))
}
