package persistence.postgres

import id.toId
import org.koin.core.annotation.Single
import persistence.dao.ServerDAO
import persistence.model.Server

@Single(createdAtStart = true, binds = [ServerDAO::class])
internal class ServerPostgresDAO(
    private val client: PostgresClient,
) : ServerDAO {
    override suspend fun list(): List<Server> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT server_id, name, url
                    FROM server
                    ORDER BY name ASC
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(
                                    Server(
                                        serverId = rs.getString("server_id").toId(),
                                        name = rs.getString("name"),
                                        url = rs.getString("url"),
                                    ),
                                )
                            }
                        }
                    }
                }
        }
}
