plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":service:core"))
    api(project(":service:onboarding"))
    api(project(":service:owner"))
    api(project(":service:error-report"))
    api(project(":service:organization"))
    api(project(":service:contract"))
    api(project(":service:delivery-template"))
    api(project(":service:producer-account"))
    api(project(":service:producer"))
    api(project(":service:product-type"))
    api(project(":service:member"))
    api(project(":service:member-join-request"))
    api(project(":service:member-invitation"))
    api(project(":service:organization-request"))
    api(project(":service:producer-request"))
    api(project(":service:attendance"))
    api(project(":service:exchange"))
    api(project(":service:notification"))
    api(project(":service:activation"))

    api(project(":lib:http"))
    api(project(":lib:authentication"))
    api(project(":lib:serialization"))
    api(project(":lib:properties"))
    api(project(":lib:coroutine"))
    api(project(":persistence:wire"))
    api(project(":persistence:dao"))

    testImplementation(libs.coroutines.test)
    testImplementation(libs.slf4j.simple)
}

ksp {
    arg("KOIN_CONFIG_CHECK", "false")
}

group = "service"
