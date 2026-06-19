---
name: koin
description: Koin dependency injection patterns for this project. Use when creating a new module, annotating a service or DAO, wiring deployments, or debugging injection errors. Covers @Module/@ComponentScan/@Single, binds, createdAtStart, module composition, and KSP setup.
---

## Convention plugin

Any module that uses Koin annotations must apply `ioc-convention` in its `build.gradle.kts`:
```kotlin
plugins {
    id("ioc-convention")
    // ...
}
```

This adds `koin-core`, `koin-annotations`, `koin-ksp-compiler` (via KSP), and test dependencies. It also sets:
- `KOIN_CONFIG_CHECK=true` — compile-time validation of the graph
- `KOIN_DEFAULT_MODULE=false` — no implicit default module

**Exception**: `service:data` explicitly overrides `KOIN_CONFIG_CHECK` to `false` because it depends on DAO interfaces that are only satisfied at deployment time.

## Annotating a service or DAO

```kotlin
@Single(createdAtStart = true)
class MyService(private val myDao: MyDAO) {
    // ...
}
```

For DAOs that implement an interface, always specify `binds`:
```kotlin
@Single(createdAtStart = true, binds = [MyDAO::class])
internal class MyPostgresDAO(private val client: PostgresClient) : MyDAO {
    // ...
}
```

- `createdAtStart = true` — eagerly instantiated; catches wiring errors at startup, not at first call
- `binds` — exposes the interface to Koin consumers, not the concrete class
- Use `internal` on implementations; the interface is the public contract

## Defining a module

```kotlin
@Module
@ComponentScan   // discovers all @Single/@Factory/@Scope in the same package tree
class MyModule

// Or with manual declarations + component scan:
@Module(includes = [PropertiesModule::class])
@ComponentScan
class PostgresModule {
    @Single(createdAtStart = true)
    internal fun postgresClient(properties: Properties): PostgresClient = PostgresClient(properties)
}
```

`@ComponentScan` is sufficient for most modules — it picks up all annotated classes in the package. Only use manual `@Single` declarations for top-level infrastructure objects (DB clients, etc.) that can't be annotated directly.

## Module composition in deployments

KSP generates a `.module` extension on each `@Module` class. Wire them in `startKoin`:

```kotlin
// deploy/jvm/Main.kt pattern
val koin = startKoin {
    modules(
        DataModule().module,
        PostgresModule().module,
        GoTrueAuthenticationModule().module,
        GoTrueInstanceConfigModule().module,
        HttpModule().module,
        MyNewModule().module,   // add here
    )
}
```

Import with `import org.koin.ksp.generated.module`.

## Deployment-specific wiring

Some interfaces have different implementations per deployment:
- `UserProvisioningPort`: `GoTrueUserProvisioningAdapter` (jvm) vs `CognitoUserProvisioningAdapter` (lambda)
- `AuthenticationService`: `GoTrueAuthenticationModule` (`lib:authentication-gotrue`, jvm) vs `CognitoAuthenticationModule` (`lib:authentication-cognito`, lambda)
- `InstanceConfig` + `InstanceAuthConfigSerializers`: `GoTrueInstanceConfigModule` (`lib:instance-config-gotrue`, jvm) vs `CognitoInstanceConfigModule` (`lib:instance-config-cognito`, lambda). Each adapter also registers its polymorphic `InstanceAuthConfig` subtype so the routing layer's Json can serialize the discovery doc.

When adding a deployment-specific adapter, annotate it in `deploy:jvm` or `deploy:lambda` only — not in `service:data`.

## Testing with Koin

Route tests use `startKoin { modules(module { ... }) }` with manual DSL bindings (not annotations). Always `stopKoin()` in `@AfterEach` and annotate the test class with `@Execution(ExecutionMode.SAME_THREAD)`.

Service and DAO unit tests do **not** use Koin — instantiate dependencies directly.

## Resolving from KoinApplication

In `dataRoutingModule`, services are resolved eagerly from `koin.koin.get<T>()`. Do not inject via `by inject()` in route files.

## Common pitfalls

- **Missing `binds`**: if a consumer injects `MyDAO` but the `@Single` class has no `binds = [MyDAO::class]`, Koin will fail at startup with "no definition found".
- **KOIN_CONFIG_CHECK=true**: adding a `@Single` in a module with config check enabled but not satisfying all its dependencies will cause a compile-time error — fix the graph, don't disable the check.
- **Circular dependencies**: `@Single(createdAtStart = true)` makes cycles fail at startup. Use constructor injection exclusively; avoid property injection.
