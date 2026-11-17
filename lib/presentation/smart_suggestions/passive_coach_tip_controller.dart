import 'dart:async';

import 'package:flutter/widgets.dart';

typedef PassiveCoachTipRequest = Future<String?> Function(Locale locale);

/// Keeps a passive coach response aligned with the app's current locale.
/// Locale changes invalidate old work but never start a new AI request.
class PassiveCoachTipController extends ChangeNotifier {
  PassiveCoachTipController({
    required Locale locale,
    required PassiveCoachTipRequest requestTip,
  }) : _locale = locale,
       _requestTip = requestTip;

  final PassiveCoachTipRequest _requestTip;
  Locale _locale;
  int _requestSequence = 0;
  bool _initialLoadStarted = false;

  String? tip;
  bool isLoading = false;
  bool needsRefresh = false;
  bool hasError = false;

  Locale get locale => _locale;

  void updateLocale(Locale locale) {
    if (_locale.languageCode == locale.languageCode) return;

    _locale = locale;
    _requestSequence++;
    tip = null;
    isLoading = false;
    needsRefresh = true;
    hasError = false;
    notifyListeners();
  }

  Future<void> loadInitial() async {
    if (_initialLoadStarted || needsRefresh) return;
    _initialLoadStarted = true;
    await _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    if (isLoading) return;
    final locale = _locale;
    final sequence = ++_requestSequence;
    isLoading = true;
    hasError = false;
    notifyListeners();

    String? result;
    try {
      result = await _requestTip(locale);
    } catch (_) {
      result = null;
    }

    if (sequence != _requestSequence ||
        locale.languageCode != _locale.languageCode) {
      return;
    }

    tip = result?.trim().isNotEmpty == true ? result!.trim() : null;
    isLoading = false;
    needsRefresh = tip == null;
    hasError = tip == null;
    notifyListeners();
  }
}
