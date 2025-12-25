import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';

class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'serene_theme_palette';

  SerenePalette _palette = serenePalettes.first;
  SharedPreferences? _prefs;
  bool _initialized = false;

  SerenePalette get palette => _palette;
  bool get isReady => _initialized;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedId = _prefs?.getString(_prefsKey);
    if (savedId != null) {
      _palette = paletteById(savedId);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setPalette(String id) async {
    final next = paletteById(id);
    if (next.id == _palette.id) return;
    _palette = next;
    await _prefs?.setString(_prefsKey, id);
    notifyListeners();
  }
}
