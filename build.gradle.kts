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
    description = "Runs cross-component e2e tests (requires Docker and flutter in PATH)."
    group = "verification"
    dependsOn(includedTask("back", ":crossComponentTest"))
    dependsOn(includedTask("front", ":frontCrossComponentTest"))
}

tasks.register("allAcceptanceTests") {
    description = "Runs all acceptance tests: back acceptance + flutter acceptance + cross-component E2E tests. MUST be run before merging any feature or bug fix."
    group = "verification"
    dependsOn(
        "acceptanceTest",
        "frontAcceptanceTest",
        "crossComponentTest",
        "frontCrossComponentTest"
    )
}

tasks.register("allSonar") {
    description = "Generates back + front coverage, uploads to SonarCloud, then enforces the quality gate."
    group = "verification"
    // Coverage inputs first, then analysis, then gate enforcement.
    val backCoverage = includedTask("back", ":jacocoAggregatedReport")
    val frontCoverage = includedTask("front", ":frontTest")
    val sonar = includedTask("back", ":sonar")
    val sonarCheck = includedTask("back", ":sonarCheck")
    dependsOn(backCoverage, frontCoverage, sonar, sonarCheck)
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
