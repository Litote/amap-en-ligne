plugins {
    id("serialization-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(libs.kotlinx.datetime)
}

group = "lib"
