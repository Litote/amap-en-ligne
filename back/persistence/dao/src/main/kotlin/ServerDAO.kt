package persistence.dao

import persistence.model.Server

fun interface ServerDAO {
    suspend fun list(): List<Server>
}
