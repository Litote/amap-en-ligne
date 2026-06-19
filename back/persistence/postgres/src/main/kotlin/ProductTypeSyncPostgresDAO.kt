package persistence.postgres

import id.Id
import id.toId
import kotlinx.serialization.builtins.ListSerializer
import org.koin.core.annotation.Single
import persistence.changes.Change
import persistence.dao.ProductTypeSyncDAO
import persistence.model.BasketSize
import persistence.model.ProducerAccount
import persistence.model.ProductType
import serialization.json
import java.sql.ResultSet

@Single(createdAtStart = true, binds = [ProductTypeSyncDAO::class])
internal class ProductTypeSyncPostgresDAO(
    private val client: PostgresClient,
) : ProductTypeSyncDAO {
    override suspend fun getByProducerAccountId(producerAccountId: Id<ProducerAccount>): List<ProductType> =
        client.dataSource.query { conn ->
            conn
                .prepareStatement(
                    """
                    SELECT product_type_id, name, description, supported_basket_sizes
                    FROM product_type
                    WHERE producer_account_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerAccountId.id)
                    stmt.executeQuery().use { rs ->
                        buildList {
                            while (rs.next()) {
                                add(rs.toProductType(producerAccountId))
                            }
                        }
                    }
                }
        }

    override suspend fun put(
        productType: ProductType,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    INSERT INTO product_type (
                        producer_account_id, product_type_id, name, description, supported_basket_sizes
                    ) VALUES (?, ?, ?, ?, ?::jsonb)
                    ON CONFLICT (producer_account_id, product_type_id)
                    DO UPDATE SET
                        name = EXCLUDED.name,
                        description = EXCLUDED.description,
                        supported_basket_sizes = EXCLUDED.supported_basket_sizes
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, productType.producerAccountId.id)
                    stmt.setString(2, productType.productTypeId.id)
                    stmt.setString(3, productType.name)
                    stmt.setString(4, productType.description)
                    stmt.setString(
                        5,
                        json.encodeToString(
                            ListSerializer(BasketSize.serializer()),
                            productType.supportedBasketSizes,
                        ),
                    )
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }

    override suspend fun delete(
        id: Id<ProductType>,
        producerAccountId: Id<ProducerAccount>,
        change: Change,
    ) {
        client.dataSource.tx { conn ->
            conn
                .prepareStatement(
                    """
                    DELETE FROM product_type
                    WHERE producer_account_id = ? AND product_type_id = ?
                    """.trimIndent(),
                ).use { stmt ->
                    stmt.setString(1, producerAccountId.id)
                    stmt.setString(2, id.id)
                    stmt.executeUpdate()
                }
            upsertChange(conn, change)
        }
    }
}

private fun ResultSet.toProductType(producerAccountId: Id<ProducerAccount>): ProductType =
    ProductType(
        productTypeId = getString("product_type_id").toId(),
        producerAccountId = producerAccountId,
        supportedBasketSizes =
            json.decodeFromString(
                ListSerializer(BasketSize.serializer()),
                getString("supported_basket_sizes"),
            ),
        name = getString("name"),
        description = getString("description"),
    )
