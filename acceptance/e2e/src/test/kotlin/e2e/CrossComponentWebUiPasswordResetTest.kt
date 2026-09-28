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
internal class CrossComponentWebUiPasswordResetTest : E2eTestSupport() {
    private val producerAccountId = "web-ui-reset-e2e-producer"
    private val email = "web-ui-reset-e2e@test.invalid"
    private val password = "WebResetTest123!"
    private val newPassword = "WebResetNew456!"

    @Test
    fun `GIVEN user submits forgot-password form WHEN OTP arrives in MailHog THEN user resets password and signs in`() {
        ContainerSuite.clearEmails()
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

                        // Home screen → /login.
                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("SE CONNECTER"),
                            ).first()
                            .click()

                        // Login screen → /forgot-password.
                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("Mot de passe oublié ?"),
                            ).click()

                        // Forgot-password screen: enter email and request OTP.
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
                                AriaRole.BUTTON,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("ENVOYER LE CODE"),
                            ).click()

                        // Wait for the OTP confirmation form to appear (codeSent = true).
                        page
                            .getByRole(
                                AriaRole.TEXTBOX,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("Code de réinitialisation"),
                            ).waitFor(
                                com.microsoft.playwright.Locator
                                    .WaitForOptions()
                                    .setTimeout(30_000.0),
                            )

                        // Retrieve OTP via admin API — this returns the 6-char numeric OTP
                        // that GoTrue's /verify endpoint accepts.  extractOtpFromEmail()
                        // returns the 56-char magic-link token which GoTrue rejects as
                        // "otp_expired" when submitted to /verify.
                        val otp = ContainerSuite.getRecoveryToken(email)
                        checkNotNull(otp) { "Recovery OTP not received for $email" }

                        // Enter OTP. Flutter web uses a single reusable off-screen <input>
                        // element.  Click the accessibility element to focus it, then use
                        // keyboard.insertText() (single atomic InputEvent) to set the full value
                        // without triggering the scrollIntoView() that fill() calls, which
                        // causes Flutter to re-render and drop leading characters.
                        page
                            .getByRole(
                                AriaRole.TEXTBOX,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("Code de réinitialisation"),
                            ).click()
                        page.waitForSelector(
                            "input[aria-label='Code de réinitialisation']",
                            com.microsoft.playwright.Page
                                .WaitForSelectorOptions()
                                .setTimeout(5_000.0),
                        )
                        page.keyboard().press("Control+A")
                        page.keyboard().insertText(otp)

                        // Enter passwords. Flutter web blocks insertText() on <input type="password">
                        // (Chrome security restriction on synthetic events).  Instead: click to
                        // focus, wait 500 ms for Flutter to complete the focus re-render so the
                        // hidden input has settled, then use keyboard.type() which fires real
                        // isTrusted key events that Flutter processes correctly.
                        page
                            .getByRole(
                                AriaRole.TEXTBOX,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("Nouveau mot de passe"),
                            ).click()
                        page.waitForSelector(
                            "input[aria-label='Nouveau mot de passe']",
                            com.microsoft.playwright.Page
                                .WaitForSelectorOptions()
                                .setTimeout(5_000.0),
                        )
                        Thread.sleep(500)
                        page.keyboard().type(newPassword)

                        page
                            .getByRole(
                                AriaRole.TEXTBOX,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("Confirmer le mot de passe"),
                            ).click()
                        page.waitForSelector(
                            "input[aria-label='Confirmer le mot de passe']",
                            com.microsoft.playwright.Page
                                .WaitForSelectorOptions()
                                .setTimeout(5_000.0),
                        )
                        Thread.sleep(500)
                        page.keyboard().type(newPassword)

                        page
                            .getByRole(
                                AriaRole.BUTTON,
                                com.microsoft.playwright.Page
                                    .GetByRoleOptions()
                                    .setName("RÉINITIALISER"),
                            ).click()

                        // After a successful reset the ForgotPasswordBloc BlocListener calls
                        // context.go('/login'); the GoRouter redirect then sends the authenticated
                        // user to /product-types.
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
