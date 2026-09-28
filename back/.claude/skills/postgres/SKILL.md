---
name: postgres
description: Postgres persistence patterns for this project. Use when adding Flyway migrations, writing a PostgresDAO, running queries or transactions, or wiring contract tests. Covers DataSource.tx/query, upsert patterns, ResultSet mapping, and Testcontainers setup.
---

## Module location

All Postgres persistence lives in `persistence:postgres` (`back/persistence/postgres/`).

- DAOs: `src/main/kotlin/`
- Migrations: `src/main/resources/db/migration/` (Flyway, classpath `db/migration`)
- Tests: `src/test/kotlin/`

## Flyway migrations

Files must follow the naming convention: `V{N}__{description}.sql` where N is the next integer after the current highest. The history was squashed into a single consolidated baseline `V1__init.sql`, so the next migration is `V2`.

```sql
-- V2__my_new_table.sql
CREATE TABLE my_entity (
    my_entity_id TEXT NOT NULL,
    producer_account_id TEXT NOT NULL,
    name TEXT NOT NULL,
    extra_data JSONB,                         -- use JSONB for structured lists/objects
    created_at BIGINT NOT NULL,               -- epoch millis for timestamps
    PRIMARY KEY (producer_account_id, my_entity_id)
);
```

Rules:
- Use `TEXT` for IDs and enums (not UUID, not VARCHAR)
- Use `JSONB` for structured sub-objects (e.g., `supported_basket_sizes`)
- Use `BIGINT` for timestamps (epoch millis)
- Entity tables that participate in sync need no `changes` column — the shared `changes` table handles it
- Always run the server after adding a migration to validate Flyway applies cleanly

## DAO pattern

```kotlin
@Single(createdAtStart = true, binds = [MyEntityDAO::class])
internal class MyEntityPostgresDAO(
    private val client: PostgresClient,
) : MyEntityDAO {

    override suspend fun getByProducerAccountId(producerAccountId: Id<ProducerAccount>): List<MyEntity> =
        client.dataSource.query { conn ->
            conn.prepareStatement(
                """
                SELECT my_entity_id, name
                FROM my_entity
                WHERE producer_account_id = ?
                """.trimIndent()
            ).use { stmt ->
                stmt.setString(1, producerAccountId.id)
                stmt.executeQuery().use { rs ->
                    buildList {
                        while (rs.next()) add(rs.toMyEntity(producerAccountId))
                    }
                }
            }
        }

    override suspend fun put(entity: MyEntity, change: Change) {
        client.dataSource.tx { conn ->
            conn.prepareStatement(
                """
                INSERT INTO my_entity (producer_account_id, my_entity_id, name)
                VALUES (?, ?, ?)
                ON CONFLICT (producer_account_id, my_entity_id)
                DO UPDATE SET name = EXCLUDED.name
                """.trimIndent()
            ).use { stmt ->
                stmt.setString(1, entity.producerAccountId.id)
                stmt.setString(2, entity.myEntityId.id)
                stmt.setString(3, entity.name)
                stmt.executeUpdate()
            }
            upsertChange(conn, change)   // defined in ChangePostgresDAO.kt — always call this in tx writes
        }
    }
}

private fun ResultSet.toMyEntity(producerAccountId: Id<ProducerAccount>): MyEntity =
    MyEntity(
        myEntityId = getString("my_entity_id").toId(),
        producerAccountId = producerAccountId,
        name = getString("name"),
    )
```

Key rules:
- `DataSource.tx { }` for writes — wraps in a transaction with automatic rollback on exception
- `DataSource.query { }` for reads — no transaction overhead
- Always pass a `Change` to write methods and call `upsertChange(conn, change)` inside the same `tx` block (atomicity)
- Use `@Single(createdAtStart = true, binds = [MyEntityDAO::class])` — `binds` exposes the interface to Koin, not the impl
- `internal` visibility on the class

## JSONB serialization

For JSONB columns, encode/decode with the project `json` singleton from `serialization`:
```kotlin
import serialization.json

stmt.setString(
    5,
    json.encodeToString(ListSerializer(BasketSize.serializer()), entity.sizes)
)

// Read:
json.decodeFromString(ListSerializer(BasketSize.serializer()), rs.getString("sizes"))
```

## Contract test

Every DAO must be tested via the contract test in `persistence:dao/src/testFixtures/kotlin/`. Add an abstract class there, then wire it in both `persistence:postgres` and `persistence:dynamo`.

```kotlin
// persistence/postgres/src/test/kotlin/MyEntityPostgresDAOTest.kt
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class MyEntityPostgresDAOTest : MyEntityDAOContractTest() {
    private val container = PostgreSQLContainer("postgres:16")
    private lateinit var postgresClient: PostgresClient

    override val myEntityDao: MyEntityDAO by lazy { MyEntityPostgresDAO(postgresClient) }
    override val changeDao: ChangeDAO by lazy { ChangePostgresDAO(postgresClient) }

    @BeforeAll fun setUp() {
        container.start()
        val properties = object : Properties {
            override fun propertyOrNull(name: String): String? = when (name) {
                "POSTGRES_URL" -> container.jdbcUrl
                "POSTGRES_USER" -> container.username
                "POSTGRES_PASSWORD" -> container.password
                else -> null
            }
        }
        postgresClient = PostgresClient(properties)
    }

    @AfterAll fun tearDown() { container.stop() }
}
```

Container image: always `PostgreSQLContainer("postgres:16")` — do not change the version.
