package email.delivery

import persistence.model.EmailMessage

/**
 * Adds instance branding, shared by both deployment gateways. The subject is
 * prefixed with `[AmapEnLigne]` **only when it is not already prefixed** with a
 * `[…]` tag — AMAP-scoped emails arrive pre-prefixed with `[AMAP name]` (see
 * `amapEmailSubject`) and must not be double-branded. The instance footer is
 * always appended. Pure and non-mutating (returns a copy).
 */
fun EmailMessage.withInstanceBranding(instanceUrl: String): EmailMessage =
    copy(
        subject = if (subject.startsWith("[")) subject else "[AmapEnLigne] $subject",
        body = "$body\n\nAmapEnLigne: $instanceUrl",
    )
