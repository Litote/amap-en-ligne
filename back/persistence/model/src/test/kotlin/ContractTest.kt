package persistence.model

import id.toId
import kotlinx.datetime.LocalDate
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

internal class ContractTest {
    private fun buildContract(maxDeliveryDate: LocalDate): Contract =
        Contract(
            contractId = "contract-1".toId(),
            name = "Test contract",
            organizationId = "org-1".toId(),
            producerAccountId = "producer-1".toId(),
            minDeliveryDate = LocalDate(2025, 1, 1),
            maxDeliveryDate = maxDeliveryDate,
            deliveryCount = 20,
            seasonYear = 2025,
        )

    @Test
    fun `GIVEN today equals maxDeliveryDate WHEN isEnded THEN false`() {
        val maxDate = LocalDate(2025, 12, 31)
        val contract = buildContract(maxDate)

        assertFalse(contract.isEnded(today = maxDate))
    }

    @Test
    fun `GIVEN today is after maxDeliveryDate WHEN isEnded THEN true`() {
        val maxDate = LocalDate(2025, 12, 31)
        val contract = buildContract(maxDate)

        assertTrue(contract.isEnded(today = LocalDate(2026, 1, 1)))
    }

    @Test
    fun `GIVEN today is before maxDeliveryDate WHEN isEnded THEN false`() {
        val maxDate = LocalDate(2025, 12, 31)
        val contract = buildContract(maxDate)

        assertFalse(contract.isEnded(today = LocalDate(2025, 12, 30)))
    }
}
