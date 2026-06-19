package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.AttendanceEmailRequestSyncDAO
import persistence.dao.AttendanceEmailRequestSyncDAOContractTest
import persistence.dao.ChangeDAO

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class AttendanceEmailRequestSyncDynamoDAOTest : AttendanceEmailRequestSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val attendanceEmailRequestSyncDAO: AttendanceEmailRequestSyncDAO = AttendanceEmailRequestSyncDynamoDAO(dynamoClient)
    override val changeDAO: ChangeDAO = ChangeDynamoDAO(dynamoClient)

    override fun insertOrganization(organizationId: String) {
        // DynamoDB doesn't have FK constraints — no pre-insert needed.
    }

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
