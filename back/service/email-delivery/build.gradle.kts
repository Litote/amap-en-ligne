plugins {
    id("serialization-convention")
    id("ioc-convention")
    alias(libs.plugins.ktlint)
}

dependencies {
    api(project(":service:email"))
    api(project(":service:notification-publisher"))
    implementation(project(":persistence:dao"))
    implementation(project(":persistence:model"))
    implementation(project(":lib:authentication"))

    testImplementation(libs.coroutines.test)
    testImplementation(libs.slf4j.simple)
}

ksp {
    arg("KOIN_CONFIG_CHECK", "false")
}

group = "service"
