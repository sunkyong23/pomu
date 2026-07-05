import 'package:photo_manager/photo_manager.dart';

import '../../models/photo_category.dart';
import 'category_mapper.dart';
import 'vision_service.dart';

class AIService {
  final VisionService _visionService = VisionService();
  final CategoryMapper _categoryMapper = CategoryMapper();

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

        final category = _categoryMapper.mapLabels(labels);

        print('📁 최종 카테고리 ${i + 1}/${photos.length}: ${category.name}');

        result[category]!.add(photo);
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
}
