package deploy.jvm

import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.jupiter.api.Test
import serialization.json
import java.nio.file.Files
import java.nio.file.Path
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Guards the `acceptance/scenarios` catalog against orphan stories: every target tag must be one a
 * runner actually executes, otherwise the scenario silently never runs (as happened with a `back` tag).
 * The Flutter side is guarded by `front/test/acceptance/scenario_catalog_acceptance_test.dart`.
 */
class AcceptanceCatalogTest {
    @Test
    fun `every catalog scenario targets only executed runners`() {
        val scenarios = catalogFiles()
        assertTrue(scenarios.isNotEmpty(), "No acceptance scenario found")
        scenarios.forEach { path ->
            val scenario = json.parseToJsonElement(Files.readString(path)).jsonObject
            val fileId = path.fileName.toString().removeSuffix(".json")
            assertEquals(fileId, scenario.getValue("id").jsonPrimitive.content, "Scenario id must match its file name")
            val targets = scenario.getValue("targets").jsonArray.map { it.jsonPrimitive.content }
            assertTrue(targets.isNotEmpty(), "$fileId has no target")
            val unknown = targets - EXECUTED_TARGETS
            assertTrue(unknown.isEmpty(), "$fileId has targets no runner executes: $unknown (known: $EXECUTED_TARGETS)")
        }
    }

    private fun catalogFiles(): List<Path> =
        Files.list(resolveCatalogDir()).use { paths ->
            paths.filter { it.fileName.toString().endsWith(".json") }.sorted().toList()
        }

    private fun resolveCatalogDir(): Path {
        var current = Path.of(System.getProperty("user.dir")).toAbsolutePath()
        repeat(6) {
            val candidate = current.resolve("acceptance").resolve("scenarios")
            if (Files.isDirectory(candidate)) return candidate
            current = current.parent ?: return@repeat
        }
        error("Could not locate acceptance/scenarios from ${System.getProperty("user.dir")}")
    }

    private companion object {
        /** Target tag -> runner. Add a tag here only together with the runner that executes it. */
        val EXECUTED_TARGETS =
            setOf(
                // AcceptanceScenariosTest
                "server",
                // VolunteerRegistrationScenariosTest
                "volunteer-flow",
                // CoordinatorAssignmentScenariosTest
                "coordinator-flow",
                // TimeSlotLifecycleScenariosTest
                "time-slot-flow",
                // ContractLifecycleScenariosTest
                "contract-lifecycle",
                // OrganizationFlowScenariosTest
                "organization-flow",
                // BasketExchangeFlowScenariosTest
                "basket-exchange-flow",
                // front/test/acceptance (by scenario id)
                "flutter",
                // front/test/acceptance/cross_component web UI e2e (by scenario id)
                "web-ui",
            )
    }
}
