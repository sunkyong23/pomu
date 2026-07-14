import 'dart:convert';

import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/duplicate_photo_group.dart';

class DuplicateResultCacheService {
  static const String _groupsKey = 'duplicate_cached_groups';

  Future<void> saveGroups(List<DuplicatePhotoGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedGroups = groups.map((group) {
      return {
        'id': group.id,
        'assetIds': group.assets.map((asset) => asset.id).toList(),
      };
    }).toList();

    await prefs.setString(_groupsKey, jsonEncode(encodedGroups));
  }

  Future<int> getSavedGroupCount() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_groupsKey);

    if (savedValue == null || savedValue.isEmpty) {
      return 0;
    }

    try {
      final decoded = jsonDecode(savedValue);

      if (decoded is! List) {
        return 0;
      }

      return decoded.length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<DuplicatePhotoGroup>> loadGroups({
    int offset = 0,
    int limit = 100,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_groupsKey);

    if (savedValue == null || savedValue.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(savedValue);

      if (decoded is! List) {
        return [];
      }

      final safeOffset = offset < 0 ? 0 : offset;
      final safeLimit = limit <= 0 ? 100 : limit;

      final rawGroups = decoded.skip(safeOffset).take(safeLimit).toList();

      final restoredGroups = <DuplicatePhotoGroup>[];

      for (final rawGroup in rawGroups) {
        if (rawGroup is! Map) {
          continue;
        }

        final groupData = Map<String, dynamic>.from(rawGroup);
        final id = groupData['id'];
        final rawAssetIds = groupData['assetIds'];

        if (id is! String || rawAssetIds is! List) {
          continue;
        }

        final assetIds = rawAssetIds.whereType<String>().toList();

        if (assetIds.length <= 1) {
          continue;
        }

        final restoredAssets = await Future.wait(
          assetIds.map(AssetEntity.fromId),
        );

        final assets = restoredAssets
            .whereType<AssetEntity>()
            .where((asset) => asset.type == AssetType.image)
            .toList();

        if (assets.length <= 1) {
          continue;
        }

        restoredGroups.add(DuplicatePhotoGroup(id: id, assets: assets));
      }

      return restoredGroups;
    } catch (_) {
      return [];
    }
  }

  Future<void> removeGroupById(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_groupsKey);

    if (savedValue == null || savedValue.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(savedValue);

      if (decoded is! List) {
        return;
      }

      final updatedGroups = decoded.where((rawGroup) {
        if (rawGroup is! Map) {
          return false;
        }

        final groupData = Map<String, dynamic>.from(rawGroup);
        return groupData['id'] != groupId;
      }).toList();

      await prefs.setString(_groupsKey, jsonEncode(updatedGroups));
    } catch (_) {
      // 손상된 캐시는 다음 전체 검사에서 덮어써요.
    }
  }

  Future<void> clearGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_groupsKey);
  }
}
