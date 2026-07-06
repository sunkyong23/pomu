import 'package:photo_manager/photo_manager.dart';

import '../../models/album_definition.dart';
import '../../models/photo_category.dart';
import '../../models/photo_tag.dart';
import '../album_settings_service.dart';
import 'category_mapper.dart';
import 'vision_service.dart';

class AIService {
  final VisionService _visionService = VisionService();
  final CategoryMapper _categoryMapper = CategoryMapper();
  final AlbumSettingsService _albumSettingsService = AlbumSettingsService();

  Future<List<AlbumDefinition>> analyzePhotosToAlbums(
    List<AssetEntity> photos,
  ) async {
    final categorizedPhotos = await analyzePhotos(photos);

    final albums = <AlbumDefinition>[];

    for (final entry in categorizedPhotos.entries) {
      final category = entry.key;
      final categoryPhotos = entry.value;

      if (categoryPhotos.isEmpty) continue;

      final albumName = await _albumSettingsService.getAlbumName(category);

      albums.add(
        AlbumDefinition(
          id: category.name,
          albumName: albumName,
          photos: categoryPhotos,
          type: AlbumDefinitionType.aiCategory,
          category: category,
        ),
      );
    }

    return albums;
  }

  Future<Map<PhotoCategory, List<AssetEntity>>> analyzePhotos(
    List<AssetEntity> photos,
  ) async {
    final Map<PhotoCategory, List<AssetEntity>> result = {
      for (final category in PhotoCategory.values) category: [],
    };

    for (int i = 0; i < photos.length; i++) {
      final photo = photos[i];

      try {
        print('🔍 분석 시작 ${i + 1}/${photos.length}: ${photo.id}');

        final labels = await _visionService.analyzePhoto(photo);

        debugPrintLabels(photo.id, labels);

        final categories = _categoryMapper.mapLabels(labels);
        final tags = _categoryMapper.mapTags(labels);

        print(
          '📁 최종 카테고리 ${i + 1}/${photos.length}: '
          '${categories.map((category) => category.name).join(', ')}',
        );

        _debugPrintTags(photo.id, tags);

        for (final category in categories) {
          result[category]!.add(photo);
        }
      } catch (e) {
        print('⚠️ Vision failed ${i + 1}/${photos.length} for ${photo.id}: $e');
        result[PhotoCategory.other]!.add(photo);
      }
    }

    result.removeWhere((key, value) => value.isEmpty);

    print('✅ AI 분석 완료');
    for (final entry in result.entries) {
      print(' - ${entry.key.name}: ${entry.value.length}장');
    }

    return result;
  }

  void debugPrintLabels(String id, List<VisionLabel> labels) {
    print('📷 Photo $id');

    if (labels.isEmpty) {
      print(' - 라벨 없음');
      return;
    }

    for (final label in labels) {
      print(' - ${label.identifier}: ${label.confidence}');
    }
  }

  void _debugPrintTags(String id, List<PhotoTag> tags) {
    if (tags.isEmpty) {
      print('🏷️ 세부 태그 없음: $id');
      return;
    }

    print(
      '🏷️ 세부 태그 $id: '
      '${tags.map((tag) => tag.koreanName).join(', ')}',
    );
  }
}
