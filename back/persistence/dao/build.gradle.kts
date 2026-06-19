plugins {
    id("kotlin-convention")
    `java-test-fixtures`
    alias(libs.plugins.ktlint)
    alias(libs.plugins.aws.dynamodb)
    id("jacoco")
}

dependencies {
    api(project(":persistence:model"))
    api(project(":persistence:wire"))

    testFixturesImplementation(project(":lib:authentication"))
    testFixturesImplementation(project(":persistence:wire"))
    testFixturesImplementation(project(":persistence:model"))
    testFixturesImplementation(libs.coroutines.test)
    testFixturesImplementation(kotlin("test-junit5"))
}

group = "persistence"
