package persistence.postgres

import kotlin.time.Instant

internal fun java.sql.PreparedStatement.setLongOrNull(
    index: Int,
    value: Instant?,
) {
    if (value == null) {
        setNull(index, java.sql.Types.BIGINT)
    } else {
        setLong(index, value.toEpochMilliseconds())
    }
}

internal fun java.sql.ResultSet.getInstantOrNull(column: String): Instant? {
    val millis = getLong(column)
    return if (wasNull()) null else Instant.fromEpochMilliseconds(millis)
}
