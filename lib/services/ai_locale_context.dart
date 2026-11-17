import 'package:flutter/material.dart';

/// Converts the UI's already-resolved locale into the AI endpoint contracts.
///
/// Callers must pass the current app locale; this helper deliberately does not
/// read preferences or device settings on its own.
class AiLocaleContext {
  AiLocaleContext._();

  static const _supportedCodes = {'en', 'fr', 'es'};

  static String responseLocale(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    return _supportedCodes.contains(code) ? code : 'en';
  }

  static Map<String, String> styleCoach(Locale locale) => {
    'responseLocale': responseLocale(locale),
  };

  static Map<String, String> proseResponse(Locale locale) => {
    'responseLocale': responseLocale(locale),
  };

  static Map<String, String> suggestions(Locale locale) => {
    'language': responseLocale(locale).toUpperCase(),
  };
}
