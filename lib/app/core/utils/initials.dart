String initialsFromName(String? name) {
  if (name == null) return '?';
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';

  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    final word = parts.first;
    if (word.length == 1) return word.toUpperCase();
    return word.substring(0, 2).toUpperCase();
  }

  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.last.isNotEmpty ? parts.last[0] : '';
  final initials = (first + last).toUpperCase();
  return initials.isEmpty ? '?' : initials;
}
