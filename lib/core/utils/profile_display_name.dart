/// Returns a trimmed name when one was supplied, otherwise `null`.
String? normalizeProfileName(String? name) {
  final value = name?.trim();
  return value == null || value.isEmpty ? null : value;
}

/// Chooses a useful profile label without replacing a supplied name with email.
String resolveProfileDisplayName({
  String? authMetadataName,
  String? profileName,
  String? email,
}) {
  final metadataName = normalizeProfileName(authMetadataName);
  if (metadataName != null) return metadataName;
  final storedName = normalizeProfileName(profileName);
  if (storedName != null) return storedName;
  return email?.trim() ?? '';
}
