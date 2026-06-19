plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:authentication"))

    implementation(project(":lib:properties"))
    implementation(libs.auth0.java.jwt)
}

group = "lib"
