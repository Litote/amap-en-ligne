plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:instance-config"))

    implementation(project(":lib:properties"))
}

group = "lib"
