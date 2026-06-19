package core

import authentication.Role

interface MemberRoleProvisioningPort {
    suspend fun updateRoles(
        memberId: String,
        oldRoles: Set<Role>,
        newRoles: Set<Role>,
    )
}
