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
  Future<void> createAlbums(List<AlbumDefinition> albums) async {
    for (final album in albums) {
      if (album.isEmpty) continue;

      final success = await _albumChannelService.addPhotosToAlbum(
        albumName: album.albumName,
        photos: album.photos,
      );

      debugPrint(
        success
            ? '✅ Added ${album.photoCount} photos to ${album.albumName}'
            : '⚠️ Failed to add photos to ${album.albumName}',
      );
    }
  }

  /// 기존 코드 호환용
  Future<void> createAlbumsForCategories(
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

    await createAlbums(albums);
  }
}
