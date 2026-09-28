plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:i18n"))
    api(project(":lib:id"))

    api(libs.kotlinx.datetime)
}

group = "lib"
