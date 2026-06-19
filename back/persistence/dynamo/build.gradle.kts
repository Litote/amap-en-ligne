@file:OptIn(ExperimentalApi::class)
import aws.sdk.kotlin.hll.codegen.rendering.Visibility
import aws.smithy.kotlin.runtime.ExperimentalApi

plugins {
    id("ioc-convention")
    id("serialization-convention")
    alias(libs.plugins.ktlint)
    alias(libs.plugins.aws.dynamodb)
    id("jacoco")
}

kotlin {
    compilerOptions {
        optIn.add("aws.smithy.kotlin.runtime.ExperimentalApi")
    }
}

dependencies {
    api(project(":lib:properties"))
    api(project(":persistence:dao"))
    implementation(project(":lib:serialization"))
    implementation(libs.aws.dynamodb.mapper)
    implementation(libs.aws.dynamodb.mapper.annotations)
    implementation(libs.aws.smithy.http.client.engine.crt)

    testImplementation(testFixtures(project(":persistence:dao")))
    testImplementation(libs.coroutines)
    testImplementation(libs.coroutines.test)
    testImplementation(libs.slf4j.simple)
}

dynamoDbMapper {
    visibility = Visibility.INTERNAL
}

tasks.test {
    maxParallelForks = 1
}

group = "persistence"
