import java.net.URI

plugins {
    id("kotlin-convention")
    id("com.google.devtools.ksp")
}

dependencies {
    api(lib("koin-core"))
    api(lib("koin-annotations"))
    ksp(lib("koin-ksp-compiler"))
    testImplementation(lib("koin-test"))
    testImplementation(lib("koin-test-junit5"))
}

repositories {
    mavenCentral()
    maven { url = URI("https://repository.kotzilla.io/repository/kotzilla-platform/") }
}

if(System.getProperty("idea.sync.active") == "true") {
    sourceSets.main {
        java.srcDirs("bin/main")
    }
}


ksp {
    arg("KOIN_CONFIG_CHECK", "true")
    arg("KOIN_DEFAULT_MODULE", "false")
}
