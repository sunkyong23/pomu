import 'package:flutter/services.dart';

class DuplicateHashService {
  static const MethodChannel _channel = MethodChannel('pomu/duplicate_hash');

  Future<List<List<String>>> findSimilarGroups(
    List<String> assetIds, {
    double threshold = 8.0,
  }) async {
    if (assetIds.isEmpty) return [];

    final result = await _channel.invokeMethod<List<dynamic>>(
      'findSimilarGroups',
      {'assetIds': assetIds, 'threshold': threshold},
    );

    if (result == null) return [];

    return result
        .map(
          (group) =>
              (group as List<dynamic>).map((id) => id.toString()).toList(),
        )
        .toList();
  }
}
