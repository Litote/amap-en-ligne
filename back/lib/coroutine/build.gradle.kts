plugins {
    id("kotlin-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(libs.kotlinx.datetime)
    api(libs.coroutines)
}

group = "lib"
