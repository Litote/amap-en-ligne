import groovy.json.JsonSlurper
import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension
import org.sonarqube.gradle.SonarExtension
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse

plugins {
    base
    id("project-convention")
    alias(libs.plugins.version.catalog.update)
    alias(libs.plugins.ktlint) apply false
    alias(libs.plugins.sonarqube)
    id("jacoco")
}

val leafProjects = subprojects.filter { it.buildFile.exists() && it.path != ":e2e" }

tasks.named("check") {
    dependsOn(leafProjects.map { "${it.path}:check" })
}

// ── SonarCloud — single multi-language project (back Kotlin + front Dart) ─────
//
// The repo root is a composite build, so a single Sonar project must come from
// one scanner run whose base directory contains both back/ and front/. We apply
// the plugin here (Gradle-aware: it auto-discovers every Kotlin module's
// sources/binaries/JaCoCo) and widen the base directory to the repo root, then
// bolt on the front via the root project's own sonar.sources/sonar.tests.
//
// Coverage inputs:
//   - back  : jacocoAggregatedReport XML (sonar.coverage.jacoco.xmlReportPaths)
//   - front : flutter test --coverage lcov  (sonar.dart.lcov.reportPaths)

val aggregatedReportPath: String = layout.buildDirectory
    .file("reports/jacoco/jacocoAggregatedReport/jacocoAggregatedReport.xml")
    .get().asFile.absolutePath

val repoRoot = rootDir.parentFile

// JaCoCo XML report path(s) handed to SonarCloud. Defaults to the locally-generated
// aggregated report; CI overrides it with `-PjacocoXmlReportPaths=<comma-separated paths>`
// pointing at the per-job coverage artifacts. NB: this MUST be set through the Gradle DSL
// (here) — the SonarQube Gradle plugin gives DSL-configured `sonar.*` properties precedence
// over `-Dsonar.*` system properties, so a `-D` override is silently ignored.
val coverageXmlReportPaths: String =
    (project.findProperty("jacocoXmlReportPaths") as String?) ?: aggregatedReportPath

// Front Dart lcov path, same override mechanism (defaults to the local frontTest output).
val coverageLcovReportPaths: String =
    (project.findProperty("dartLcovReportPaths") as String?) ?: "$repoRoot/front/coverage/lcov.info"

// Shared coverage aggregation: every Kotlin leaf module's exec PLUS the
// cross-component e2e exec. The e2e back server boots in-JVM (`deploy.jvm.bootstrap`),
// so its hits land on the real service/deploy classes — `:e2e` itself stays out of
// `leafProjects` (not a coverage *target*), we only fold in its execution data.
val configureAggregatedCoverage: JacocoReport.() -> Unit = {
    executionData.setFrom(
        leafProjects.flatMap { sub ->
            sub.fileTree("${sub.layout.buildDirectory.get()}/jacoco") { include("*.exec") }
        } + fileTree("$repoRoot/acceptance/e2e/build/jacoco") { include("*.exec") },
    )

    sourceDirectories.setFrom(
        leafProjects.flatMap { sub ->
            sub.extensions.findByType(KotlinJvmProjectExtension::class)
                ?.sourceSets?.getByName("main")?.kotlin?.srcDirs
                ?: emptyList()
        },
    )

    classDirectories.setFrom(
        leafProjects.flatMap { sub ->
            sub.fileTree("${sub.layout.buildDirectory.get()}/classes/kotlin/main") {
                exclude("**/*\$\$serializer.class")
                // Koin KSP generates identical DI-glue classes (e.g. _KSP_AuthenticationAuthenticationService)
                // in several modules; aggregating them collides ("Can't add different class with same name")
                // and they are not meaningful coverage targets anyway.
                exclude("org/koin/ksp/generated/**")
            }
        },
    )

    reports {
        xml.required.set(true)
        html.required.set(false)
    }
}

// Local one-shot report (used by the `allSonar` quality loop): runs every module's
// unit tests + the back acceptance scenarios first, then aggregates. Cross-component
// e2e exec is folded in opportunistically when present (a prior `crossComponentTest`
// run) — e2e is NOT forced here because it needs the full Flutter + Playwright + Docker
// toolchain; CI captures it in its own `acceptance` job instead.
val jacocoAggregatedReport by tasks.registering(JacocoReport::class) {
    dependsOn(leafProjects.mapNotNull { it.tasks.findByName("test") })
    dependsOn(":deploy:jvm:acceptanceTest")
    configureAggregatedCoverage()
}

// CI report: aggregates whatever `.exec` files already exist (NO test dependency),
// so each CI job (back unit / acceptance + e2e) snapshots exactly the coverage it ran.
// Emits XML at build/reports/jacoco/jacocoExecReport/jacocoExecReport.xml; the `sonar`
// job then feeds the per-job XMLs to SonarCloud via `-PjacocoXmlReportPaths`.
val jacocoExecReport by tasks.registering(JacocoReport::class) {
    configureAggregatedCoverage()
}

sonar {
    properties {
        property("sonar.projectKey", "Litote_amap-en-ligne")
        property("sonar.projectName", "ael")
        property("sonar.organization", "litote")
        property("sonar.host.url", "https://sonarcloud.io")
        // Widen the analysis base directory to the repo root so front/ is in scope.
        property("sonar.projectBaseDir", repoRoot.absolutePath)
        property("sonar.coverage.jacoco.xmlReportPaths", coverageXmlReportPaths)
        // Add the front sources/tests through the root project's own properties;
        // each Kotlin subproject still contributes its auto-detected sources.
        property("sonar.sources", "${repoRoot}/front/lib")
        property("sonar.tests", "${repoRoot}/front/test")
        property("sonar.dart.lcov.reportPaths", coverageLcovReportPaths)
        // Exclude generated code: front codegen (Dart) + back KSP output (Koin DI glue under
        // build/generated/ksp). The latter otherwise floods S101 (class names like _KSP_*).
        property(
            "sonar.exclusions",
            "**/*.g.dart,**/*.freezed.dart,**/*.config.dart,**/build/generated/**",
        )
    }
}

subprojects {
    afterEvaluate {
        extensions.findByType(SonarExtension::class)?.properties {
            property("sonar.coverage.jacoco.xmlReportPaths", coverageXmlReportPaths)
        }
    }
}

// `-PsonarExternalCoverage` (set by the CI scan-only `sonar` job) means the coverage
// reports are supplied externally — downloaded job artifacts wired in via
// `-PjacocoXmlReportPaths` / `-PdartLcovReportPaths` — so the
// scan must NOT regenerate coverage. Local `allSonar` keeps the dependency (default).
if (!project.hasProperty("sonarExternalCoverage")) {
    tasks.named("sonar") {
        dependsOn(jacocoAggregatedReport)
        mustRunAfter(jacocoAggregatedReport)
    }
}

/**
 * Fetches quality gate status and open issues from SonarCloud.
 * Fails the build if the gate is not OK or any issue/hotspot remains.
 *
 * Waits for SonarCloud to finish processing the analysis (async CE task) before checking.
 *
 * Prerequisites: run `./gradlew jacocoAggregatedReport sonar` first to push the analysis.
 * Token: set `systemProp.sonar.token=<token>` in ~/.gradle/gradle.properties (or SONAR_TOKEN env).
 *
 * Full quality loop (from the repo root): `./gradlew allSonar`
 */
tasks.register("sonarCheck") {
    group = "verification"
    description = "Verifies SonarCloud quality gate: fails if gate != OK, issues > 0, or hotspots > 0."
    mustRunAfter("sonar")
    notCompatibleWithConfigurationCache("Reads sonar/report-task.txt generated at execution time")
    doLast {
        val token = project.providers.systemProperty("sonar.token")
            .orElse(project.providers.environmentVariable("SONAR_TOKEN"))
            .orNull
            ?: error("sonar.token not set. Add systemProp.sonar.token=<token> to ~/.gradle/gradle.properties")

        val projectKey = "Litote_amap-en-ligne"
        val client = HttpClient.newHttpClient()
        val slurper = JsonSlurper()

        fun fetch(url: String): Any {
            val req = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Authorization", "Bearer $token")
                .GET()
                .build()
            val resp = client.send(req, HttpResponse.BodyHandlers.ofString())
            check(resp.statusCode() == 200) {
                "SonarCloud API error ${resp.statusCode()}: ${resp.body()}"
            }
            return slurper.parseText(resp.body())
        }

        val reportTaskFile = layout.buildDirectory.file("sonar/report-task.txt").get().asFile
        if (reportTaskFile.exists()) {
            val props = java.util.Properties().also { it.load(reportTaskFile.inputStream()) }
            val ceTaskId = props.getProperty("ceTaskId")
            if (ceTaskId != null) {
                logger.lifecycle("⏳ Waiting for SonarCloud analysis (task $ceTaskId) to complete…")
                val maxWaitMs = 120_000L
                val pollIntervalMs = 5_000L
                val start = System.currentTimeMillis()
                while (true) {
                    @Suppress("UNCHECKED_CAST")
                    val taskData = fetch("https://sonarcloud.io/api/ce/task?id=$ceTaskId") as Map<String, Any>
                    @Suppress("UNCHECKED_CAST")
                    val taskStatus = (taskData["task"] as Map<String, Any>)["status"] as String
                    when (taskStatus) {
                        "SUCCESS" -> {
                            logger.lifecycle("✅ Analysis processing complete.")
                            break
                        }
                        "FAILED", "CANCELLED" -> error("SonarCloud analysis task $ceTaskId ended with status: $taskStatus")
                        else -> {
                            check(System.currentTimeMillis() - start < maxWaitMs) {
                                "Timed out waiting for SonarCloud analysis task $ceTaskId (status: $taskStatus)"
                            }
                            Thread.sleep(pollIntervalMs)
                        }
                    }
                }
            }
        }

        @Suppress("UNCHECKED_CAST")
        val qgData = fetch("https://sonarcloud.io/api/qualitygates/project_status?projectKey=$projectKey") as Map<String, Any>
        @Suppress("UNCHECKED_CAST")
        val gateStatus = (qgData["projectStatus"] as Map<String, Any>)["status"] as String

        @Suppress("UNCHECKED_CAST")
        val issuesData = fetch("https://sonarcloud.io/api/issues/search?projectKeys=$projectKey&resolved=false&ps=1") as Map<String, Any>
        val issueCount = (issuesData["total"] as Number).toInt()

        @Suppress("UNCHECKED_CAST")
        val hotspotsData = fetch("https://sonarcloud.io/api/hotspots/search?projectKey=$projectKey&status=TO_REVIEW&ps=1") as Map<String, Any>
        @Suppress("UNCHECKED_CAST")
        val hotspotCount = ((hotspotsData["paging"] as Map<String, Any>)["total"] as Number).toInt()

        logger.lifecycle("")
        logger.lifecycle("╔════════════════════════════════════╗")
        logger.lifecycle("║     SonarCloud Quality Gate        ║")
        logger.lifecycle("╠════════════════════════════════════╣")
        logger.lifecycle("║  Gate    : ${gateStatus.padEnd(24)}║")
        logger.lifecycle("║  Issues  : ${issueCount.toString().padEnd(24)}║")
        logger.lifecycle("║  Hotspots: ${hotspotCount.toString().padEnd(24)}║")
        logger.lifecycle("╚════════════════════════════════════╝")
        logger.lifecycle("")

        val failures = buildList {
            if (gateStatus != "OK") add("quality gate status is '$gateStatus' (expected OK)")
            if (issueCount > 0) add("$issueCount unresolved issue(s)")
            if (hotspotCount > 0) add("$hotspotCount unreviewed security hotspot(s)")
        }

        check(failures.isEmpty()) {
            "❌ SonarCloud check FAILED:\n${failures.joinToString("\n") { "  • $it" }}"
        }

        logger.lifecycle("✅ SonarCloud quality gate passed — 0 issues, 0 hotspots.")
    }
}

tasks.register("crossComponentTest") {
    description = "Runs cross-component e2e tests (requires Docker and flutter in PATH)."
    group = "verification"
    dependsOn(":e2e:test")
}

tasks.register("format") {
    dependsOn(leafProjects.map { "${it.path}:formatKotlin" })
}

tasks.register("lint") {
    dependsOn(leafProjects.map { "${it.path}:lintKotlin" })
}

tasks.register("acceptanceTest") {
    dependsOn(":deploy:jvm:acceptanceTest")
}
