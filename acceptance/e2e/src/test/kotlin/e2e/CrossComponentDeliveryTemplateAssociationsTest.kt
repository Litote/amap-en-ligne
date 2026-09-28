package e2e

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentDeliveryTemplateAssociationsTest : E2eTestSupport() {
    private val organizationId = "delivery-template-sync-e2e-org-${System.currentTimeMillis()}"

    @Test
    fun `GIVEN admin org scope WHEN delivery linked to template via sync THEN UI shows association and blocks deletion`() {
        ContainerSuite.insertOrganization(
            organizationId = organizationId,
            name = "AMAP Delivery Templates E2E",
            contactEmail = "contact+$organizationId@test.invalid",
        )
        // memberId == sub by invariant: insert the admin so AuthorizedScopeResolver can resolve the org scope
        ContainerSuite.insertMember(
            memberId = "delivery-template-sync-admin-sub",
            organizationId = organizationId,
            roles = listOf("ADMIN"),
            firstName = "Test",
            lastName = "Admin",
            email = "delivery-template-sync-admin@test.invalid",
        )
        val token =
            ContainerSuite.mintGoTrueToken(
                subject = "delivery-template-sync-admin-sub",
                email = "delivery-template-sync-admin@test.invalid",
                roles = listOf("ADMIN"),
                organizationId = organizationId,
            )

        runFlutterTests(
            testFile = "test/acceptance/cross_component/delivery_template_associations_e2e_test.dart",
            dartDefines =
                mapOf(
                    "BACK_URL" to "http://127.0.0.1:$backPort",
                    "BEARER_TOKEN" to token,
                    "ORGANIZATION_ID" to organizationId,
                ),
        )
    }
}
