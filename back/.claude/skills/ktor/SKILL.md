---
name: ktor
description: Ktor routing patterns for this project. Use when adding HTTP endpoints, handling auth, writing route tests, or modifying CORS/middleware. Covers route structure, auth guard, error responses, and testApplication setup.
---

## Module structure

All routes live in `service:routing`. Each route is an internal extension on `Route`, wired in `RoutingModule.kt` inside `Application.dataRoutingModule(koin: KoinApplication)`.

Adding an endpoint requires:
1. Create `MyRoute.kt` in `service/routing/src/main/kotlin/`
2. Register the route in `dataRoutingModule` (resolve service from koin, call the new extension)
3. If the route is **unauthenticated**, add the path to `AuthenticationService.isUnauthenticatedPath`
4. Wire test in `service/routing/src/test/kotlin/`

## Route patterns

### Unauthenticated route
```kotlin
internal fun Route.myPublicRoute(myService: MyService, httpService: HttpService) {
    get("/v1/public/my-resource") {
        call.respond(myService.list())
    }
    post("/v1/my-action") {
        val body = call.receive<MyRequestBody>()
        when (val outcome = myService.doAction(body)) {
            is MyOutcome.Success -> call.respond(HttpStatusCode.Created, outcome.result)
            is MyOutcome.Conflict -> call.respond(
                HttpStatusCode.Conflict,
                httpService.conflictError(call.request.path(), outcome.field),
            )
        }
    }
}
```

### Authenticated route
```kotlin
internal fun Route.myAuthenticatedRoute(
    myService: MyService,
    authenticationService: AuthenticationService,
    httpService: HttpService,
) {
    post("/v1/my-secure-endpoint") {
        val info = call.authenticatedInfoOrRespond(authenticationService, httpService) ?: return@post
        val body = call.receive<MyRequestBody>()
        val response = myService.handle(info, body)
        call.respond(response)
    }
}
```

`authenticatedInfoOrRespond` returns `null` and sends 401 automatically for expired/invalid/wrong-server tokens. Never call it on a path listed in `isUnauthenticatedPath`.

### Admin route (requires role check)
See `AdminRoute.kt` — after `authenticatedInfoOrRespond`, check `info.roles.contains(Role.ADMIN)` and respond 403 via `httpService.forbiddenError(path)` if not.

## Error responses

Always use `HttpService` methods — never construct `ErrorResponse` manually:
- `httpService.internalServerError(path)` — 500
- `httpService.expiredTokenError(path)` — 401 EXPIRED_AUTH_TOKEN
- `httpService.invalidTokenError(path)` — 401 INVALID_AUTH_TOKEN
- `httpService.wrongServerError(path, tokenIssuer)` — 401 WRONG_SERVER
- `httpService.conflictError(path, field)` — 409 CONFLICT
- `httpService.forbiddenError(path)` — 403 FORBIDDEN

## CORS

`service:routing` does not handle CORS — no preflight blocks, no plugin install. CORS is configured per deployment:

- **Lambda** — API Gateway V2 (`infra/modules/api_gateway/main.tf`) handles preflight and adds `Access-Control-*` headers. `ktor-server-cors` is not on the Lambda classpath.
- **JVM** — `deploy:jvm/src/main/kotlin/CorsConfig.kt` installs `ktor-server-cors` conditionally on `CORS_ALLOW_ORIGINS` (`*` for dev, csv whitelist otherwise; unset = no plugin = same-origin prod default).

When adding a route, do not add `options(...)` blocks or any CORS-related code in `service:routing` — the standard plugin handles preflight at the deploy level.

## Test pattern

```kotlin
@Execution(ExecutionMode.SAME_THREAD)
internal class MyRouteTest {
    @AfterEach fun tearDown() { stopKoin() }

    @Test
    fun `GIVEN ... WHEN ... THEN ...`() = runTest {
        val myService = mockk<MyService>()
        coEvery { myService.doSomething(any()) } returns expectedResult

        val koin = startKoin {
            modules(module {
                single<MyService> { myService }
                single<AuthenticationService> { stubAuthenticationService }
                single { HttpService() }
                single { stubInstanceConfig }
                single { mockk<PublicService>(relaxed = true) }
                single { mockk<AdminService>(relaxed = true) }
                single { mockk<ActivationService>(relaxed = true) }
                single { mockk<DataService>(relaxed = true) }
                single<Properties> { Properties.Instance }
            })
        }

        testApplication {
            application { dataRoutingModule(koin) }
            val response = client.post("/v1/my-endpoint") {
                headers.append(HttpHeaders.Authorization, "Bearer test-token")
                headers.append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                setBody("""{"key":"value"}""")
            }
            assertEquals(HttpStatusCode.OK, response.status)
        }
    }
}
```

Key constraints:
- `@Execution(ExecutionMode.SAME_THREAD)` — required because Koin is global state
- Always call `stopKoin()` in `@AfterEach`
- The stub auth service in existing tests accepts any non-null Bearer token as valid; copy the pattern from `SyncRouteTest.kt`
- Every test must register all services in the Koin module (use `mockk(relaxed = true)` for unused ones)
