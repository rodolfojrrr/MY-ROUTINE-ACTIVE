import 'package:flutter/foundation.dart';

import 'app_store.dart';
import 'app_theme.dart';

class AppAppearanceController extends ChangeNotifier {
  AppAppearanceController(this.store);

  final AppStore store;
  AppAccentPalette _palette = AppAccentPalette.blue;

  AppAccentPalette get palette => _palette;

  Future<void> loadForActiveAccount() async {
    final saved = await store.readUserPreference('appearance_accent');
    _palette = AppAccentPalette.values.firstWhere(
      (item) => item.name == saved,
      orElse: () => AppAccentPalette.blue,
    );
    AppColors.applyAccent(_palette);
    notifyListeners();
  }

  Future<void> select(AppAccentPalette palette) async {
    if (_palette == palette) return;
    _palette = palette;
    AppColors.applyAccent(palette);
    await store.writeUserPreference('appearance_accent', palette.name);
    notifyListeners();
  }

  void reset() {
    _palette = AppAccentPalette.blue;
    AppColors.applyAccent(_palette);
    notifyListeners();
  }
}
