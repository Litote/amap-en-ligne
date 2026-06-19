package persistence.dynamo

import org.junit.jupiter.api.AfterAll
import org.junit.jupiter.api.BeforeAll
import org.junit.jupiter.api.TestInstance
import persistence.dao.MemberInvitationSyncDAO
import persistence.dao.MemberInvitationSyncDAOContractTest

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class MemberInvitationSyncDynamoDAOTest : MemberInvitationSyncDAOContractTest() {
    private val dynamoClient = DynamoTestInfra.newClient()
    override val dao: MemberInvitationSyncDAO = MemberInvitationSyncDynamoDAO(dynamoClient)

    @BeforeAll
    fun setUp() {
        DynamoTestInfra.ensureStarted()
        DynamoTestInfra.createTable(dynamoClient)
    }

    @AfterAll
    fun tearDown() {
        DynamoTestInfra.deleteTable(dynamoClient)
    }

    override fun insertOrganization(organizationId: String) {
        // DynamoDB doesn't have FK constraints — no pre-insert needed.
    }
}
