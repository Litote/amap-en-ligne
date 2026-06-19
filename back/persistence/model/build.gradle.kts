plugins {
    id("serialization-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:authentication"))
    api(project(":lib:id"))
    api(project(":lib:i18n"))
}

group = "persistence"
