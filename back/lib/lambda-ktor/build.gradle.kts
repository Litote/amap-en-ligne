plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:lambda"))

    api(libs.ktor.server.core)
    api(libs.coroutines)

    testImplementation(libs.coroutines.test)
}

group = "lib"
