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

@EnabledIfEnvironmentVariable(named = "E2E_RUN_WEB_UI", matches = "true")
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@Execution(ExecutionMode.SAME_THREAD)
internal class CrossComponentWebUiAdminProducerCreationTest : E2eTestSupport() {
    private val unique = System.currentTimeMillis()
    private val organizationId = "web-ui-admin-producer-org-$unique"
    private val email = "web-ui-admin-producer+$unique@test.invalid"
    private val password = "WebUiAdminProducer123!"

    @Test
    fun `GIVEN authenticated admin WHEN they click add producer THEN enroll flow opens instead of staying on list`() {
        ContainerSuite.insertOrganization(
            organizationId = organizationId,
            name = "AMAP UI Producteurs $unique",
            contactEmail = "contact+$organizationId@test.invalid",
        )
        ContainerSuite.createUser(
            email = email,
            password = password,
            producerAccountId = organizationId,
            roles = listOf("ADMIN", "COORDINATOR"),
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
                        page.addInitScript(
                            flutterServerConfigScript(
                                backendUrl = "http://127.0.0.1:$backPort",
                                gotrueUrl = gotrueUrl,
                            ),
                        )

                        page.navigate("http://127.0.0.1:$webPort")
                        activateFlutterSemantics(page)

                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                Page
                                    .GetByRoleOptions()
                                    .setName("SE CONNECTER"),
                            ).first()
                            .click()

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
                        page.locator("input[aria-label='Email']").fill(email)

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
                        page.locator("input[aria-label='Mot de passe']").fill(password)

                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                Page
                                    .GetByRoleOptions()
                                    .setName("SE CONNECTER"),
                            ).click()
                        page.waitForURL(
                            "**/dashboard**",
                            Page
                                .WaitForURLOptions()
                                .setTimeout(30_000.0),
                        )

                        page.navigate("http://127.0.0.1:$webPort/admin/producers")
                        activateFlutterSemantics(page)
                        page.getByText("Ajouter un producteur").waitFor()
                        val addProducerButton =
                            page
                                .getByRole(
                                    AriaRole.BUTTON,
                                    Page
                                        .GetByRoleOptions()
                                        .setName("Ajouter un producteur"),
                                ).first()
                        addProducerButton.evaluate("element => element.click()")
                        page.getByText("Inscrire un producteur — Étape 1").waitFor()

                        val createNoAccountButton =
                            page
                                .getByRole(
                                    AriaRole.BUTTON,
                                    Page
                                        .GetByRoleOptions()
                                        .setName("Créer un producteur sans compte"),
                                ).first()
                        createNoAccountButton.evaluate("element => element.click()")

                        page.getByText("Créer un producteur sans compte — Étape 2").waitFor()
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
