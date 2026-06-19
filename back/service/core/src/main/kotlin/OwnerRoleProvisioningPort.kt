package core

interface OwnerRoleProvisioningPort {
    suspend fun updateOwnerRole(ownerId: String)
}
