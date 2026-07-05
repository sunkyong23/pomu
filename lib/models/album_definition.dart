import 'package:photo_manager/photo_manager.dart';

import 'photo_category.dart';

enum AlbumDefinitionType { aiCategory, custom, travel, event, recommendation }

class AlbumDefinition {
  final String id;
  final String albumName;
  final List<AssetEntity> photos;
  final AlbumDefinitionType type;
  final PhotoCategory? category;

  const AlbumDefinition({
    required this.id,
    required this.albumName,
    required this.photos,
    required this.type,
    this.category,
  });

  int get photoCount => photos.length;

  bool get isEmpty => photos.isEmpty;
}
