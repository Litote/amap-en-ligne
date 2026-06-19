package properties

interface Properties {
    /**
     * Return an env or system String property or null if not found
     */
    fun propertyOrNull(name: String): String? = System.getProperty(name) ?: System.getenv(name)

    /**
     * Return an env or system String property or raise an exception if not found
     */
    fun propertyOrFail(name: String): String = propertyOrNull(name) ?: error("property $name not found")

    /**
     * Is this env or system property exists?
     */
    fun propertyExists(name: String): Boolean = propertyOrNull(name) != null

    /**
     * Return an env or system String property.
     */
    fun property(
        name: String,
        defaultValue: String,
    ): String = propertyOrNull(name) ?: defaultValue

    /**
     * Return an env or system Int property.
     */
    fun intProperty(
        name: String,
        defaultValue: Int,
    ): Int = propertyOrNull(name)?.toInt() ?: defaultValue

    /**
     * Return an env or system Long property.
     */
    fun longProperty(
        name: String,
        defaultValue: Long,
    ): Long = propertyOrNull(name)?.toLong() ?: defaultValue

    /**
     * Return an env or system Boolean property.
     */
    fun booleanProperty(
        name: String,
        defaultValue: Boolean,
    ): Boolean = propertyOrNull(name)?.toBoolean() ?: defaultValue

    /**
     * Return an env or system List property.
     */
    fun listProperty(
        name: String,
        defaultValue: List<String>,
        separator: String = ",",
    ): List<String> = propertyOrNull(name)?.split(separator) ?: defaultValue

    /**
     * Return an env or system Map property.
     */
    fun mapProperty(
        name: String,
        defaultValue: Map<String, String>,
        entrySeparator: String = "|",
        keyValueSeparator: String = "=",
    ): Map<String, String> =
        propertyOrNull(name)
            ?.split(entrySeparator)
            ?.associate { text -> text.split(keyValueSeparator).let { it[0] to it[1] } }
            ?: defaultValue

    /**
     * Return an env or system Map of List property.
     */
    fun mapListProperty(
        name: String,
        defaultValue: Map<String, List<String>>,
        entrySeparator: String = "|",
        keyValueSeparator: String = "=",
        listSeparator: String = ",",
    ): Map<String, List<String>> =
        propertyOrNull(name)
            ?.split(entrySeparator)
            ?.associate { text ->
                text.split(keyValueSeparator).let { it[0] to it[1].split(listSeparator) }
            } ?: defaultValue

    object Instance : Properties
}
