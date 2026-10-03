import 'package:flutter/services.dart';

class DuplicateHashService {
  static const MethodChannel _channel = MethodChannel('pomu/duplicate_hash');

  // DuplicateDetectorService와 동일한 기본값으로 맞춰
  // 다른 호출부에서 threshold를 생략해도 결과 기준이 흔들리지 않게 합니다.
  static const double defaultThreshold = 0.4;

  Future<List<List<String>>> findSimilarGroups(
    List<String> assetIds, {
    double threshold = defaultThreshold,
  }) async {
    if (assetIds.length <= 1) {
      return const <List<String>>[];
    }

    final result = await _channel.invokeMethod<List<dynamic>>(
      'findSimilarGroups',
      <String, dynamic>{'assetIds': assetIds, 'threshold': threshold},
    );

    if (result == null || result.isEmpty) {
      return const <List<String>>[];
    }

    final groups = <List<String>>[];

    for (final rawGroup in result) {
      if (rawGroup is! List) {
        continue;
      }

      final ids = <String>[];

      for (final rawId in rawGroup) {
        final id = rawId?.toString();

        if (id != null && id.isNotEmpty) {
          ids.add(id);
        }
      }

      if (ids.length > 1) {
        groups.add(ids);
      }
    }

    return groups;
  }
}
