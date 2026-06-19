package core

import authentication.Role

fun interface MemberRoleProvisioningPort {
    suspend fun updateRoles(
        memberId: String,
        oldRoles: Set<Role>,
        newRoles: Set<Role>,
    )
}
