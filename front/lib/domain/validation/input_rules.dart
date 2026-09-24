/// Client-side input rules shared by the forms.
///
/// Each rule mirrors the back `core.InputRules`: the front check is UX (French
/// message, submit blocked), the back check is authoritative — see root
/// `AGENTS.md` → "Validation on both sides". Keep both in sync.
library;

/// Maximum length of a name-like field (person, organization, product…).
const int kMaxNameLength = 200;

/// Maximum length of an email address.
const int kMaxEmailLength = 254;

/// Maximum length of a free-text comment.
const int kMaxCommentLength = 2000;

const String kFieldRequiredMessage = 'Ce champ est requis.';
const String kInvalidEmailMessage = 'Adresse email invalide.';
const String kInvalidUrlMessage = "L'URL n'est pas valide (ex. https://…).";

final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// `local@domain.tld` without whitespace (same shape as the back).
bool isValidEmail(String value) {
  final trimmed = value.trim();
  return trimmed.length <= kMaxEmailLength && _emailRegExp.hasMatch(trimmed);
}

/// Absolute `http`/`https` URL with a host.
bool isValidHttpUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null) return false;
  return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

/// Required name-like field: non-blank, at most [kMaxNameLength] characters.
String? requiredName(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return kFieldRequiredMessage;
  if (value!.length > kMaxNameLength) {
    return 'Ce champ ne doit pas dépasser $kMaxNameLength caractères.';
  }
  return null;
}

/// Required, well-formed email address.
String? requiredEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return kFieldRequiredMessage;
  return isValidEmail(trimmed) ? null : kInvalidEmailMessage;
}

/// Optional email: empty is fine, otherwise it must be well-formed.
String? optionalEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return isValidEmail(trimmed) ? null : kInvalidEmailMessage;
}

/// Optional http(s) URL: empty is fine, otherwise it must be valid.
String? optionalHttpUrl(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return isValidHttpUrl(trimmed) ? null : kInvalidUrlMessage;
}

/// IANA time zones offered for an AMAP (metropolitan France, overseas
/// departments / territories, French-speaking neighbours). The back decodes
/// `Organization.timezone` as a `TimeZone`: an unknown id makes the whole sync
/// request undecodable, so the zone is picked from a list, never typed.
const List<String> kSupportedTimezones = [
  'Europe/Paris',
  'Europe/Brussels',
  'Europe/Luxembourg',
  'Europe/Zurich',
  'Europe/Monaco',
  'America/Guadeloupe',
  'America/Martinique',
  'America/Cayenne',
  'America/Toronto',
  'Indian/Reunion',
  'Indian/Mayotte',
  'Pacific/Noumea',
  'Pacific/Tahiti',
];

final RegExp _languageCodeRegExp = RegExp(r'^[a-z]{2}$');

/// Required two-letter language code (`fr`), same rule as the back
/// (`OrganizationValidation`).
String? requiredLanguageCode(String? value) =>
    _languageCodeRegExp.hasMatch(value?.trim() ?? '')
    ? null
    : 'Code de langue à deux lettres attendu (ex. fr).';
