import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_store.dart';
import 'app_theme.dart';

class AppAppearanceController extends ChangeNotifier {
  AppAppearanceController(this.store);

  final AppStore store;
  AppAccentPalette _palette = AppAccentPalette.blue;
  AppVisualProfile _profile =
      AppVisualProfile.fromPreset(AppAccentPalette.blue);
  bool _custom = false;

  AppAccentPalette get palette => _palette;
  AppVisualProfile get profile => _profile;
  bool get isCustom => _custom;

  Future<void> loadForActiveAccount() async {
    final savedProfile =
        await store.readUserPreference('appearance_profile_v2');
    final saved = await store.readUserPreference('appearance_accent');
    _palette = AppAccentPalette.values.firstWhere(
      (item) => item.name == saved,
      orElse: () => AppAccentPalette.blue,
    );
    if (savedProfile != null && savedProfile.isNotEmpty) {
      try {
        _profile = AppVisualProfile.fromJson(
          (jsonDecode(savedProfile) as Map).cast<String, dynamic>(),
        );
        _custom = true;
      } catch (_) {
        _profile = AppVisualProfile.fromPreset(_palette);
        _custom = false;
      }
    } else {
      _profile = AppVisualProfile.fromPreset(_palette);
      _custom = false;
    }
    AppColors.applyProfile(_profile);
    notifyListeners();
  }

  Future<void> select(AppAccentPalette palette) async {
    _palette = palette;
    _profile = AppVisualProfile.fromPreset(palette);
    _custom = false;
    AppColors.applyProfile(_profile);
    await store.writeUserPreference('appearance_accent', palette.name);
    await store.writeUserPreference('appearance_profile_v2', '');
    notifyListeners();
  }

  Future<void> customize(AppVisualProfile profile) async {
    _profile = profile;
    _custom = true;
    AppColors.applyProfile(profile);
    await store.writeUserPreference(
      'appearance_profile_v2',
      jsonEncode(profile.toJson()),
    );
    notifyListeners();
  }

  void reset() {
    _palette = AppAccentPalette.blue;
    _profile = AppVisualProfile.fromPreset(_palette);
    _custom = false;
    AppColors.applyProfile(_profile);
    notifyListeners();
  }
}
