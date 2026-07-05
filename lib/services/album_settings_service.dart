import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_category.dart';

class AlbumSettingsService {
  static const _prefix = 'album_name_';

  Future<String?> getCustomAlbumName(PhotoCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFor(category));
  }

  Future<String> getDefaultAlbumName(PhotoCategory category) async {
    return 'Pomu ${category.albumName}';
  }

  Future<String> getAlbumName(PhotoCategory category) async {
    final customName = await getCustomAlbumName(category);

    if (customName == null || customName.trim().isEmpty) {
      return getDefaultAlbumName(category);
    }

    return customName;
  }

  Future<void> setAlbumName(PhotoCategory category, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      await resetAlbumName(category);
      return;
    }

    await prefs.setString(_keyFor(category), trimmedName);
  }

  Future<void> resetAlbumName(PhotoCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(category));
  }

  Future<void> resetAllAlbumNames() async {
    for (final category in PhotoCategory.values) {
      await resetAlbumName(category);
    }
  }

  String _keyFor(PhotoCategory category) {
    return '$_prefix${category.name}';
  }
}
