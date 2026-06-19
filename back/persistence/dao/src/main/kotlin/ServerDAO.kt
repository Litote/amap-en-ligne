package persistence.dao

import persistence.model.Server

interface ServerDAO {
    suspend fun list(): List<Server>
}
