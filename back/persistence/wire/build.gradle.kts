plugins {
    id("serialization-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:id"))
    api(project(":persistence:model"))
}

group = "persistence"
