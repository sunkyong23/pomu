import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/album_definition.dart';
import '../models/photo_category.dart';
import 'album_settings_service.dart';
import 'photo_album_channel_service.dart';

class AlbumService {
  final PhotoAlbumChannelService _albumChannelService =
      PhotoAlbumChannelService();

  final AlbumSettingsService _albumSettingsService = AlbumSettingsService();

  /// 앞으로 사용할 메인 함수
  ///
  /// 모든 앨범 생성에 성공하면 true,
  /// 하나라도 실패하면 false를 반환합니다.
  Future<bool> createAlbums(List<AlbumDefinition> albums) async {
    for (final album in albums) {
      if (album.isEmpty) continue;

      final success = await _albumChannelService.addPhotosToAlbum(
        albumName: album.albumName,
        photos: album.photos,
      );

      if (!success) {
        debugPrint('⚠️ Failed to add photos to ${album.albumName}');

        return false;
      }

      debugPrint('✅ Added ${album.photoCount} photos to ${album.albumName}');
    }

    return true;
  }

  /// 기존 코드 호환용
  Future<bool> createAlbumsForCategories(
    Map<PhotoCategory, List<AssetEntity>> categorizedPhotos,
  ) async {
    final albums = <AlbumDefinition>[];

    for (final entry in categorizedPhotos.entries) {
      final category = entry.key;
      final photos = entry.value;

      if (photos.isEmpty) continue;

      final albumName = await _albumSettingsService.getAlbumName(category);

      albums.add(
        AlbumDefinition(
          id: category.name,
          albumName: albumName,
          photos: photos,
          type: AlbumDefinitionType.aiCategory,
          category: category,
        ),
      );
    }

    return createAlbums(albums);
  }
}
