import 'package:flutter/material.dart';
import 'l10n.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  String getString(String key) {
    return AppTranslations.data[_currentLocale.languageCode]?[key] ?? key;
  }

  void changeLanguage(String code) {
    _currentLocale = Locale(code);
    notifyListeners();
  }
}