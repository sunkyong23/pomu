import 'package:photo_manager/photo_manager.dart';

import '../../models/photo_category.dart';
import 'vision_service.dart';

class AIService {
  final VisionService _visionService = VisionService();

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

        result[PhotoCategory.other]!.add(photo);
      } catch (e) {
        // Vision이 특정 사진에서 실패해도 전체 정리는 계속 진행
        // ignore: avoid_print
        print('⚠️ Vision failed for ${photo.id}: $e');
        result[PhotoCategory.other]!.add(photo);
      }
    }

    result.removeWhere((key, value) => value.isEmpty);
    return result;
  }

  void debugPrintLabels(String id, List<VisionLabel> labels) {
    // ignore: avoid_print
    print('📷 Photo $id');
    for (final label in labels) {
      // ignore: avoid_print
      print(' - ${label.identifier}: ${label.confidence}');
    }
  }
}
