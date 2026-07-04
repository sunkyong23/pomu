import 'package:photo_manager/photo_manager.dart';

import '../models/photo_category.dart';
import 'photo_album_channel_service.dart';

class AlbumService {
  final PhotoAlbumChannelService _albumChannelService =
      PhotoAlbumChannelService();

  Future<void> createAlbumsForCategories(
    Map<PhotoCategory, List<AssetEntity>> categorizedPhotos,
  ) async {
    for (final entry in categorizedPhotos.entries) {
      final category = entry.key;
      final photos = entry.value;

      if (photos.isEmpty) continue;

      final albumName = 'Pomu ${category.albumName}';

      final success = await _albumChannelService.addPhotosToAlbum(
        albumName: albumName,
        photos: photos,
      );

      print(
        success
            ? '✅ Added ${photos.length} photos to $albumName'
            : '⚠️ Failed to add photos to $albumName',
      );
    }
  }
}
