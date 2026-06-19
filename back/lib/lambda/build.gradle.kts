plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:properties"))
    api(project(":lib:coroutine"))
    api(project(":lib:serialization"))
    api(project(":lib:logging"))
    api(project(":lib:http"))
}

group = "lib"
