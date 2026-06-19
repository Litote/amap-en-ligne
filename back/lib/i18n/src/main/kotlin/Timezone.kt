package i18n

import io.github.oshai.kotlinlogging.KotlinLogging
import kotlinx.datetime.TimeZone

const val DEFAULT_TIMEZONE: String = "Europe/Paris"

fun String.toTimeZone(): TimeZone =
    try {
        TimeZone.of(this)
    } catch (e: Throwable) {
        logger.error(e) { "Error parsing TimeZone from string: $this" }
        TimeZone.of(DEFAULT_TIMEZONE)
    }

private val logger = KotlinLogging.logger {}
