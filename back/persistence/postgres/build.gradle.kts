plugins {
    id("ioc-convention")
    id("serialization-convention")
    alias(libs.plugins.ktlint)
    id("jacoco")
}

dependencies {
    api(project(":lib:properties"))
    api(project(":persistence:dao"))
    implementation(project(":lib:serialization"))
    implementation(libs.coroutines)
    implementation(libs.flyway.core)
    implementation(libs.flyway.postgres)
    implementation(libs.hikari)
    implementation(libs.postgres.jdbc)

    testImplementation(testFixtures(project(":persistence:dao")))
    testImplementation(libs.coroutines)
    testImplementation(libs.coroutines.test)
    testImplementation(libs.slf4j.simple)
    testImplementation(libs.testcontainers)
    testImplementation(libs.testcontainers.junit.jupiter)
    testImplementation(libs.testcontainers.postgres)
}

group = "persistence"
