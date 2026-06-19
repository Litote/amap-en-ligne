plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:authentication"))
    api(project(":lib:http"))
    api(project(":lib:instance-config"))
    api(project(":lib:serialization"))
    api(project(":service:sync"))
    api(project(":persistence:wire"))

    api(libs.ktor.server.core)
    implementation(libs.ktor.server.content.negotiation)
    implementation(libs.ktor.server.status.pages)
    implementation(libs.ktor.serialization.kotlinx.json)

    testImplementation(project(":lib:instance-config-gotrue"))
    testImplementation(libs.ktor.server.test.host)
    testImplementation(libs.coroutines.test)
}

group = "service"
