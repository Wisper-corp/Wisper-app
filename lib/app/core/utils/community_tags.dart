/// Community tag pills are encoded inside the group `description` field as a
/// pipe-separated line appended after the user's own description:
///
///   My community description
///   Trade: Local B2B | Market: Wholesale | Category: Furniture & Home Décor | Suffix: MKT
///
/// `Suffix:` is intentionally skipped — it is appended to the community *name*
/// (e.g. "10 Wills Fashion MKT") and would be a duplicate as a pill.
///
/// Only the keys the create/edit community screens actually write are treated
/// as tags. Matching on any "word: value" would turn an ordinary sentence in
/// the user's own description ("Best deals: everyday low prices") into a pill.
/// Ordered by how much each tag identifies the community. `Category` (the
/// industry) is first because the card must always show it, even when the
/// others collapse behind a "+N" chip.
const _tagKeys = ['Category', 'Trade', 'Market'];

List<String> parseCommunityTags(String? description) {
  if (description == null || description.isEmpty) return const [];

  final found = <String, String>{};
  for (final line in description.split('\n')) {
    for (final part in line.split('|')) {
      final trimmed = part.trim();

      final colonIdx = trimmed.indexOf(':');
      if (colonIdx == -1) continue;

      final key = trimmed.substring(0, colonIdx).trim();
      if (!_tagKeys.contains(key)) continue;

      final value = trimmed.substring(colonIdx + 1).trim();
      if (value.isNotEmpty) found.putIfAbsent(key, () => value);
    }
  }
  return [for (final k in _tagKeys) if (found[k] != null) found[k]!];
}

/// Compact subscriber count, e.g. 12200 -> "12.2k", 1500000 -> "1.5M".
String formatSubscriberCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}k';
  }
  return '$count';
}

/// Makes a value safe to put into the pipe-encoded tag line.
///
/// Tags live inside the description as
/// "Trade: X | Market: Y | Category: Z | Suffix: S", so a value containing a
/// pipe or a colon would split into a tag that was never meant to exist — or
/// silently swallow the ones after it. Newlines end the line entirely.
///
/// Also caps the length: these are shown inline as pills beside a community
/// name, where a long one pushes everything else off the row.
String sanitizeTagValue(String value, {int maxLength = 32}) {
  final cleaned = value
      .replaceAll(RegExp(r'[|:\n\r]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return cleaned.length <= maxLength
      ? cleaned
      : cleaned.substring(0, maxLength).trim();
}
