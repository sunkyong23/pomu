import 'package:photo_manager/photo_manager.dart';

import '../models/photo_category.dart';

class AIService {
  Future<Map<PhotoCategory, List<AssetEntity>>> analyzePhotos(
    List<AssetEntity> photos,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    final Map<PhotoCategory, List<AssetEntity>> result = {
      for (final category in PhotoCategory.values) category: [],
    };

    for (var i = 0; i < photos.length; i++) {
      final category = PhotoCategory.values[i % PhotoCategory.values.length];
      result[category]!.add(photos[i]);
    }

    result.removeWhere((key, value) => value.isEmpty);

    return result;
  }
}
