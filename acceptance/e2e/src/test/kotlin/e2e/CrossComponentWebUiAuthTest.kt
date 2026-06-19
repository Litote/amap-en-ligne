package e2e

import com.microsoft.playwright.BrowserType
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
internal class CrossComponentWebUiAuthTest : E2eTestSupport() {
    private val producerAccountId = "web-ui-auth-e2e-producer"
    private val email = "web-ui-auth-e2e@test.invalid"
    private val password = "WebUiAuthTest123!"

    @Test
    fun `GIVEN valid credentials WHEN user signs in on the web app THEN product types screen is shown`() {
        ContainerSuite.createUser(
            email = email,
            password = password,
            producerAccountId = producerAccountId,
            roles = listOf("PRODUCER"),
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

                        // Inject server config before Flutter initialises so the app uses the
                        // test containers rather than the hardcoded localhost:8080 preset.
                        page.addInitScript(
                            flutterServerConfigScript(
                                backendUrl = "http://127.0.0.1:$backPort",
                                gotrueUrl = gotrueUrl,
                            ),
                        )

                        page.navigate("http://127.0.0.1:$webPort")
                        // NETWORKIDLE never fires when Flutter app retries unreachable endpoints.
                        page.waitForLoadState(LoadState.DOMCONTENTLOADED)

                        // Flutter renders a 1×1 off-screen placeholder that, when activated,
                        // replaces itself with the full flt-semantics accessibility tree.
                        // JS click bypasses Playwright's viewport check on the hidden element.
                        page.waitForSelector(
                            "flt-semantics-placeholder",
                            com.microsoft.playwright.Page
                                .WaitForSelectorOptions()
                                .setTimeout(15_000.0),
                        )
                        page.evaluate("document.querySelector('flt-semantics-placeholder').click()")
                        page.waitForSelector(
                            "flt-semantics",
                            com.microsoft.playwright.Page
                                .WaitForSelectorOptions()
                                .setTimeout(10_000.0),
                        )

                        // Home screen → click "SE CONNECTER" to navigate to /login.
                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("SE CONNECTER"),
                            ).first()
                            .click()

                        // Fill credentials. Click the accessibility element first to trigger
                        // Flutter's off-screen input creation, then type.
                        page
                            .getByRole(
                                AriaRole.TEXTBOX,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("Email"),
                            ).click()
                        // Flutter creates off-screen <input> elements for visible text fields.
                        // Use fill() (atomic JS value + input event) instead of keyboard.type()
                        // to avoid characters being dropped when the element scrolls into view.
                        page.waitForSelector(
                            "input[aria-label='Email']",
                            com.microsoft.playwright.Page
                                .WaitForSelectorOptions()
                                .setTimeout(5_000.0),
                        )
                        page.locator("input[aria-label='Email']").fill(email)

                        page
                            .getByRole(
                                AriaRole.TEXTBOX,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("Mot de passe"),
                            ).click()
                        page.waitForSelector(
                            "input[aria-label='Mot de passe']",
                            com.microsoft.playwright.Page
                                .WaitForSelectorOptions()
                                .setTimeout(5_000.0),
                        )
                        page.locator("input[aria-label='Mot de passe']").fill(password)

                        // Submit login form.
                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("SE CONNECTER"),
                            ).click()

                        // Assert: product types screen is shown after successful login.
                        page.waitForURL(
                            "**/product-types**",
                            com.microsoft.playwright.Page
                                .WaitForURLOptions()
                                .setTimeout(30_000.0),
                        )
                    }
            }
        } finally {
            webServer.stop(0)
        }
    }
}
