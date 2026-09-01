import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _contactPhoneKey = 'app_contact_phone';
  static const _defaultContactPhone = '01020185701';

  String _contactPhone = _defaultContactPhone;
  bool _isLoading = true;

  String get contactPhone => _contactPhone;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _contactPhone = prefs.getString(_contactPhoneKey) ?? _defaultContactPhone;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateContactPhone(String phone) async {
    _contactPhone = phone.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contactPhoneKey, _contactPhone);
  }
}
