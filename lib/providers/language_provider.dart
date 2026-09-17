import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider() {
    final String saved = StorageService.instance.locale;
    _locale = _supported.contains(saved) ? Locale(saved) : const Locale('fa');
    if (saved != _locale.languageCode) {
      StorageService.instance.setLocale(_locale.languageCode);
    }
  }

  static const Set<String> _supported = <String>{'fa', 'en'};
  Locale _locale = const Locale('fa');

  Locale get locale => _locale;
  String get code => _locale.languageCode;
  bool get isRtl => code == 'fa';
  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  Future<void> setLanguage(String languageCode) async {
    if (!_supported.contains(languageCode)) return;
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    notifyListeners();
    await StorageService.instance.setLocale(languageCode);
  }
}
