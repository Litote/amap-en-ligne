rootProject.name = "back"

pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
    includeBuild("../convention")
}

dependencyResolutionManagement {
    @Suppress("UnstableApiUsage")
    repositories {
        mavenCentral()
    }
    versionCatalogs {
        create("libs") {
            from(files("../gradle/libs.versions.toml"))
        }
    }
}

include(":e2e")
project(":e2e").projectDir = file("../acceptance/e2e")

include(
    ":lib:authentication",
    ":lib:authentication-cognito",
    ":lib:authentication-gotrue",
    ":lib:coroutine",
    ":lib:http",
    ":lib:i18n",
    ":lib:id",
    ":lib:instance-config",
    ":lib:instance-config-cognito",
    ":lib:instance-config-gotrue",
    ":lib:lambda",
    ":lib:lambda-ktor",
    ":lib:lang",
    ":lib:logging",
    ":lib:properties",
    ":lib:serialization",
    ":persistence:wire",
    ":persistence:dao",
    ":persistence:dynamo",
    ":persistence:model",
    ":persistence:postgres",
    ":service:organization",
    ":service:contract",
    ":service:delivery-template",
    ":service:producer-account",
    ":service:producer",
    ":service:product-type",
    ":service:member",
    ":service:member-join-request",
    ":service:member-invitation",
    ":service:organization-request",
    ":service:producer-request",
    ":service:attendance",
    ":service:exchange",
    ":service:notification",
    ":service:error-report",
    ":service:owner",
    ":service:activation",
    ":service:email",
    ":service:email-delivery",
    ":service:provisioning-gotrue",
    ":service:provisioning-cognito",
    ":service:notification-publisher",
    ":service:sync",
    ":service:core",
    ":service:onboarding",
    ":service:routing",
    ":deploy:jvm",
    ":deploy:lambda",
)
