package e2e

import com.microsoft.playwright.BrowserType
import com.microsoft.playwright.Page
import com.microsoft.playwright.Playwright
import com.microsoft.playwright.options.AriaRole
import com.microsoft.playwright.options.LoadState
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable
import org.junit.jupiter.api.parallel.Execution
import org.junit.jupiter.api.parallel.ExecutionMode
import java.nio.file.Path

/**
 * Cross-component web UI test for the volunteer self-registration flow.
 *
 * Covers:
 *  1. A VOLUNTEER logs in and navigates to /planning.
 *  2. They tap [S'INSCRIRE] on a STANDARD slot of an upcoming delivery.
 *  3. The button changes to [SE DÉSINSCRIRE] after the optimistic write.
 *  4. They tap [SE DÉSINSCRIRE] and the button reverts to [S'INSCRIRE].
 *
 * Relevant acceptance scenarios:
 *  - volunteer-self-registration.json
 *  - volunteer-self-unregister.json
 *
 * Infrastructure notes:
 *  - The organization is seeded directly into Postgres via JDBC (deliveries
 *    are stored as JSONB on the `organization` row).
 *  - The volunteer user is created in GoTrue with `organization_id` claim and
 *    a matching `member` row is inserted so the back can resolve the memberId.
 *  - Flutter web input quirks (see AI_CONTEXT.md):
 *    - text fields: click → waitForSelector → Control+A → insertText
 *    - password fields: click → waitForSelector → sleep(500) → type
 */
@EnabledIfEnvironmentVariable(named = "E2E_RUN_WEB_UI", matches = "true")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentWebUiVolunteerRegistrationTest : E2eTestSupport() {
    private val unique = System.currentTimeMillis()
    private val organizationId = "web-ui-volunteer-org-$unique"
    private val deliveryId = "web-ui-volunteer-delivery-$unique"
    private val contractId = "web-ui-volunteer-contract-$unique"
    private val email = "web-ui-volunteer+$unique@test.invalid"
    private val password = "WebUiVolunteer123!"

    /**
     * JSONB payload for a single upcoming CONFIRMED delivery with one STANDARD
     * slot (capacity 2, 0 registrations) — used to seed `organization.deliveries`.
     */
    private val deliveryJson: String
        get() =
            """
            [{
              "delivery_id": "$deliveryId",
              "organization_id": "$organizationId",
              "scheduled_date": "2099-06-15T18:00:00",
              "status": "CONFIRMED",
              "min_volunteers_required": 2,
              "basket_descriptions": [],
              "contracts": [
                {
                  "contract_id": "$contractId",
                  "coordinators": ["coordinator-seed"],
                  "basket_quantity": 10,
                  "delivery_description": "Livraison test bénévole",
                  "status": "PENDING",
                  "slots": [
                    {
                      "start_time": "2099-06-15T18:00:00",
                      "end_time": "2099-06-15T20:00:00",
                      "activity_type": "RECEPTION",
                      "required_volunteers": 2,
                      "current_registrations": 0,
                      "status": "OPEN",
                      "slot_kind": "STANDARD",
                      "registrations": []
                    }
                  ]
                }
              ]
            }]
            """.trimIndent()

    @Test
    fun `GIVEN volunteer on planning page WHEN register to slot THEN SE DESINSCRIRE shown and reverts after unregister`() {
        // --- Seed Postgres ---
        ContainerSuite.insertOrganizationWithDelivery(
            organizationId = organizationId,
            name = "AMAP UI Bénévoles $unique",
            contactEmail = "contact+$organizationId@test.invalid",
            deliveryJson = deliveryJson,
        )

        // Create the volunteer user in GoTrue. The returned sub is used to
        // create a matching member row so the back can resolve memberId.
        val volunteerSub =
            ContainerSuite.createUser(
                email = email,
                password = password,
                organizationId = organizationId,
                roles = listOf("VOLUNTEER"),
            )

        ContainerSuite.insertMember(
            memberId = volunteerSub,
            organizationId = organizationId,
            roles = listOf("VOLUNTEER"),
            firstName = "Alice",
            lastName = "Bénévole",
            email = email,
        )

        val webBuildDir = buildFlutterWeb()
        val (webPort, webServer) = serveStaticFiles(webBuildDir)
        try {
            Playwright.create().use { playwright ->
                playwright
                    .chromium()
                    .launch(
                        BrowserType
                            .LaunchOptions()
                            .setExecutablePath(
                                Path.of("/snap/chromium/current/usr/lib/chromium-browser/chrome"),
                            ).setHeadless(true)
                            .setArgs(
                                listOf(
                                    "--no-sandbox",
                                    "--disable-gpu",
                                    "--force-renderer-accessibility",
                                ),
                            ),
                    ).use { browser ->
                        val page = browser.newPage()

                        // Inject server config before Flutter initialises so the
                        // app talks to the test containers instead of localhost:8080.
                        page.addInitScript(
                            flutterServerConfigScript(
                                backendUrl = "http://127.0.0.1:$backPort",
                                gotrueUrl = gotrueUrl,
                            ),
                        )

                        page.navigate("http://127.0.0.1:$webPort")
                        activateFlutterSemantics(page)

                        // --- Login ---
                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                Page
                                    .GetByRoleOptions()
                                    .setName("SE CONNECTER"),
                            ).first()
                            .click()

                        // Email field — text input: click → waitForSelector → Ctrl+A → insertText
                        page
                            .getByRole(
                                AriaRole.TEXTBOX,
                                Page
                                    .GetByRoleOptions()
                                    .setName("Email"),
                            ).click()
                        page.waitForSelector(
                            "input[aria-label='Email']",
                            Page
                                .WaitForSelectorOptions()
                                .setTimeout(5_000.0),
                        )
                        page.keyboard().press("Control+A")
                        page.keyboard().insertText(email)

                        // Password field — password input: click → waitForSelector → sleep(500) → type
                        page
                            .getByRole(
                                AriaRole.TEXTBOX,
                                Page
                                    .GetByRoleOptions()
                                    .setName("Mot de passe"),
                            ).click()
                        page.waitForSelector(
                            "input[aria-label='Mot de passe']",
                            Page
                                .WaitForSelectorOptions()
                                .setTimeout(5_000.0),
                        )
                        Thread.sleep(500)
                        page.keyboard().type(password)

                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                Page
                                    .GetByRoleOptions()
                                    .setName("SE CONNECTER"),
                            ).click()

                        // Volunteer lands on /dashboard after login.
                        page.waitForURL(
                            "**/dashboard**",
                            Page
                                .WaitForURLOptions()
                                .setTimeout(30_000.0),
                        )

                        // --- Navigate to /planning ---
                        page.navigate("http://127.0.0.1:$webPort/planning")
                        activateFlutterSemantics(page)

                        // Wait until the planning screen has loaded content
                        // (not in loading state — the delivery card should appear).
                        page
                            .getByRole(AriaRole.HEADING)
                            .filter(
                                com.microsoft.playwright.Locator
                                    .FilterOptions()
                                    .setHasText("Planning des livraisons"),
                            ).waitFor(
                                com.microsoft.playwright.Locator
                                    .WaitForOptions()
                                    .setTimeout(30_000.0),
                            )

                        // --- Register to the STANDARD slot ---
                        // The button label is either "S'INSCRIRE" (standard) or
                        // "S'INSCRIRE MAINTENANT 🚨" (urgent, < 50% filled).
                        // Both variants start with "S'INSCRIRE" so we use a
                        // partial text match.
                        val registerButton =
                            page
                                .getByRole(
                                    AriaRole.BUTTON,
                                    Page
                                        .GetByRoleOptions()
                                        .setName("S'INSCRIRE"),
                                ).first()

                        registerButton.waitFor(
                            com.microsoft.playwright.Locator
                                .WaitForOptions()
                                .setTimeout(30_000.0),
                        )
                        // Use evaluate() to click programmatically — avoids
                        // Playwright's viewport/scrollIntoView check on Flutter elements.
                        registerButton.evaluate("el => el.click()")

                        // After the optimistic write the button should switch to
                        // [SE DÉSINSCRIRE].
                        val unregisterButton =
                            page
                                .getByRole(
                                    AriaRole.BUTTON,
                                    Page
                                        .GetByRoleOptions()
                                        .setName("SE DÉSINSCRIRE"),
                                ).first()
                        unregisterButton.waitFor(
                            com.microsoft.playwright.Locator
                                .WaitForOptions()
                                .setTimeout(15_000.0),
                        )

                        // --- Unregister from the slot ---
                        unregisterButton.evaluate("el => el.click()")

                        // After unregistering the button reverts to [S'INSCRIRE].
                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                Page
                                    .GetByRoleOptions()
                                    .setName("S'INSCRIRE"),
                            ).first()
                            .waitFor(
                                com.microsoft.playwright.Locator
                                    .WaitForOptions()
                                    .setTimeout(15_000.0),
                            )
                    }
            }
        } finally {
            webServer.stop(0)
        }
    }

    private fun activateFlutterSemantics(page: Page) {
        page.waitForLoadState(LoadState.DOMCONTENTLOADED)
        page.waitForSelector(
            "flt-semantics-placeholder",
            Page
                .WaitForSelectorOptions()
                .setTimeout(15_000.0),
        )
        page.evaluate("document.querySelector('flt-semantics-placeholder').click()")
        page.waitForSelector(
            "flt-semantics",
            Page
                .WaitForSelectorOptions()
                .setTimeout(10_000.0),
        )
    }
}
