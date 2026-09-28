package core

import kotlinx.datetime.LocalDate
import kotlinx.datetime.LocalTime

private val FRENCH_MONTH_NAMES =
    listOf(
        "janvier",
        "février",
        "mars",
        "avril",
        "mai",
        "juin",
        "juillet",
        "août",
        "septembre",
        "octobre",
        "novembre",
        "décembre",
    )

/** Long French date of the notification copy: "1er octobre 2026", "15 octobre 2026". */
fun LocalDate.toFrenchLongDate(): String {
    val dayLabel = if (day == 1) "1er" else day.toString()
    return "$dayLabel ${FRENCH_MONTH_NAMES[month.ordinal]} $year"
}

/** French time of the notification copy: "18h00", "9h05". */
fun LocalTime.toFrenchTime(): String = "${hour}h${minute.toString().padStart(2, '0')}"
