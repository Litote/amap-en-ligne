plugins {
    id("kotlin-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(libs.logging)
    api(libs.slf4j.simple)
}

group = "lib"
