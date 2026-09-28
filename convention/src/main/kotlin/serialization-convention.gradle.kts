plugins {
    id("kotlin-convention")
}

plugin("serialization")

dependencies {
    implementation(lib("serialization"))
}
