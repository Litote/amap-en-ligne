/// Text matching shared by the search fields (members, contracts, users):
/// letter case and French accents are ignored, so « cecile » finds
/// « Cécile » and « Françoise » is found by « francoise ».
library;

const _kAccented = {
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'á': 'a',
  'ã': 'a',
  'å': 'a',
  'ç': 'c',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'í': 'i',
  'ì': 'i',
  'ñ': 'n',
  'ô': 'o',
  'ö': 'o',
  'ó': 'o',
  'ò': 'o',
  'õ': 'o',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ú': 'u',
  'ÿ': 'y',
  'ý': 'y',
  'œ': 'oe',
  'æ': 'ae',
};

/// [text] lowercased, accents removed and ligatures (œ, æ) expanded.
String normalizeForSearch(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(_kAccented[char] ?? char);
  }
  return buffer.toString();
}

/// Whether [query] (trimmed) occurs in one of [fields], ignoring letter case
/// and accents. An empty query matches everything; null fields are skipped.
bool matchesSearch(String query, Iterable<String?> fields) {
  final needle = normalizeForSearch(query.trim());
  if (needle.isEmpty) return true;
  return fields.any(
    (field) => field != null && normalizeForSearch(field).contains(needle),
  );
}
