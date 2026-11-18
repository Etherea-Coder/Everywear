/// Builds the persisted machine-facing wardrobe descriptor.
///
/// `color`, `material`, and `category` are the analysis fields whose values
/// must not vary with the current UI language. Localized `*Label` fields are
/// display-only and are intentionally excluded.
String buildClothingSemanticLabel(Map<String, dynamic>? analysis) {
  if (analysis == null) return '';
  return [analysis['color'], analysis['material'], analysis['category']]
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty && value.toLowerCase() != 'unknown')
      .join(' ');
}
