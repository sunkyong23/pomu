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

    for (final photo in photos) {
      try {
        final labels = await _visionService.analyzePhoto(photo);

        debugPrintLabels(photo.id, labels);

        final category = _categoryMapper.mapLabels(labels);
        result[category]!.add(photo);
      } catch (e) {
        print('⚠️ Vision failed for ${photo.id}: $e');
        result[PhotoCategory.other]!.add(photo);
      }
    }

    result.removeWhere((key, value) => value.isEmpty);
    return result;
  }

  void debugPrintLabels(String id, List<VisionLabel> labels) {
    print('📷 Photo $id');
    for (final label in labels) {
      print(' - ${label.identifier}: ${label.confidence}');
    }
  }
}
