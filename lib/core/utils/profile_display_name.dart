/// Chooses a useful profile label without replacing a supplied name with email.
String resolveProfileDisplayName({
  String? authMetadataName,
  String? profileName,
  String? email,
}) {
  for (final candidate in [authMetadataName, profileName]) {
    final value = candidate?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return email?.trim() ?? '';
}
