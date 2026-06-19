plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
}

dependencies {
    api(project(":service:core"))

    testImplementation(libs.coroutines.test)
    testImplementation(libs.slf4j.simple)
}

ksp {
    arg("KOIN_CONFIG_CHECK", "false")
}

group = "service"
