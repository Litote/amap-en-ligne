plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:http"))
    api(project(":lib:authentication"))
    api(project(":lib:serialization"))
    api(project(":lib:properties"))
    api(project(":lib:coroutine"))
    api(project(":persistence:wire"))
    api(project(":persistence:dao"))
    api(project(":service:email"))
    api(project(":service:notification-publisher"))

    testImplementation(libs.coroutines.test)
    testImplementation(libs.slf4j.simple)
}

ksp {
    arg("KOIN_CONFIG_CHECK", "false")
}

group = "service"
