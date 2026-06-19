package persistence.dynamo

import id.toId
import kotlinx.datetime.TimeZone
import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.ChangeDAO
import persistence.dao.ProducerSyncDAO
import persistence.dao.ProducerSyncDAOContractTest
import persistence.model.UserSettings
import kotlin.time.Instant

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class ProducerSyncDynamoDAOTest : ProducerSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val producerSyncDAO: ProducerSyncDAO = ProducerSyncDynamoDAO(dynamoClient)
    override val changeDAO: ChangeDAO = ChangeDynamoDAO(dynamoClient)

    override fun buildTestUserSettings(now: Instant): UserSettings =
        UserSettings(
            language = "fr",
            timezone = TimeZone.of("Europe/Paris"),
            serverId = "server-1".toId(),
            lastUpdatedInstant = now,
        )

    @BeforeAll
    fun setUp() {
        DynamoTestInfra.ensureStarted()
        DynamoTestInfra.createTable(dynamoClient)
    }

    @AfterAll
    fun tearDown() {
        DynamoTestInfra.deleteTable(dynamoClient)
    }
}
