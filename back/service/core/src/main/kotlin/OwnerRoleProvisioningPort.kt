package core

fun interface OwnerRoleProvisioningPort {
    suspend fun updateOwnerRole(ownerId: String)
}
