package provisioning.cognito

import aws.sdk.kotlin.services.cognitoidentityprovider.model.AttributeType
import aws.sdk.kotlin.services.cognitoidentityprovider.model.UserType
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class CognitoUserProvisioningAdapterTest {
    private fun user(vararg attributes: Pair<String, String>): UserType =
        UserType {
            this.attributes =
                attributes.map { (name, value) ->
                    AttributeType {
                        this.name = name
                        this.value = value
                    }
                }
        }

    @Test
    fun `GIVEN a non-empty user list WHEN extractSubFromUserList THEN returns the sub of the first user`() {
        val result = extractSubFromUserList(listOf(user("sub" to "sub-existing", "email" to "a@b.com")))

        assertEquals("sub-existing", result)
    }

    @Test
    fun `GIVEN an empty user list WHEN extractSubFromUserList THEN returns null`() {
        val result = extractSubFromUserList(emptyList())

        assertNull(result)
    }

    @Test
    fun `GIVEN a user without a sub attribute WHEN extractSubFromUserList THEN returns null`() {
        val result = extractSubFromUserList(listOf(user("email" to "a@b.com")))

        assertNull(result)
    }
}
