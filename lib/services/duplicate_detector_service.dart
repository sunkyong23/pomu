import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/duplicate_photo_group.dart';
import 'duplicate_hash_service.dart';
import 'photo_library_service.dart';

class DuplicateDetectorService {
  final PhotoLibraryService _photoLibraryService = PhotoLibraryService();
  final DuplicateHashService _hashService = DuplicateHashService();

  static const Duration _duplicateTimeWindow = Duration(seconds: 5);

  // Vision FeaturePrint 거리.
  // 낮을수록 더 엄격해요.
  static const double _visionDistanceThreshold = 0.4;

  Future<List<DuplicatePhotoGroup>> findDuplicateCandidates({
    int limit = 1000,
  }) async {
    final assets = await _photoLibraryService.loadRecentPhotos(
      limit: limit,
      ignoreDebugLimit: true,
    );

    final imageAssets = assets.where((asset) {
      return asset.type == AssetType.image;
    }).toList();

    final resolutionGroups = <String, List<AssetEntity>>{};

    for (final asset in imageAssets) {
      final key = _buildResolutionKey(asset);
      resolutionGroups.putIfAbsent(key, () => []);
      resolutionGroups[key]!.add(asset);
    }

    final timeCandidateGroups = <List<AssetEntity>>[];

    for (final entry in resolutionGroups.entries) {
      final sortedAssets = _sortAssets(entry.value);
      final clusters = _clusterByTimeWindow(sortedAssets);

      for (final cluster in clusters) {
        if (cluster.length <= 1) continue;
        timeCandidateGroups.add(cluster);
      }
    }

    final duplicateGroups = <DuplicatePhotoGroup>[];

    for (final candidateGroup in timeCandidateGroups) {
      final visuallySimilarGroups = await _filterVisuallySimilarGroups(
        candidateGroup,
      );

      for (final group in visuallySimilarGroups) {
        if (group.length <= 1) continue;

        final firstAsset = group.first;
        final id =
            '${_buildResolutionKey(firstAsset)}_${firstAsset.createDateTime.millisecondsSinceEpoch}';

        duplicateGroups.add(DuplicatePhotoGroup(id: id, assets: group));
      }
    }

    duplicateGroups.sort((a, b) {
      final countCompare = b.count.compareTo(a.count);
      if (countCompare != 0) return countCompare;

      return b.assets.first.createDateTime.compareTo(
        a.assets.first.createDateTime,
      );
    });

    debugPrint(
      '🧹 중복 후보 그룹 ${duplicateGroups.length}개 발견 '
      '/ 시간 후보 ${timeCandidateGroups.length}개',
    );

    return duplicateGroups;
  }

  String _buildResolutionKey(AssetEntity asset) {
    return '${asset.width}x${asset.height}';
  }

  List<List<AssetEntity>> _clusterByTimeWindow(List<AssetEntity> assets) {
    if (assets.isEmpty) return [];

    final clusters = <List<AssetEntity>>[];
    var currentCluster = <AssetEntity>[assets.first];

    for (var i = 1; i < assets.length; i++) {
      final previous = currentCluster.last;
      final current = assets[i];

      final diff = current.createDateTime.difference(previous.createDateTime);

      if (diff.abs() <= _duplicateTimeWindow) {
        currentCluster.add(current);
      } else {
        clusters.add(currentCluster);
        currentCluster = [current];
      }
    }

    clusters.add(currentCluster);

    return clusters;
  }

  Future<List<List<AssetEntity>>> _filterVisuallySimilarGroups(
    List<AssetEntity> assets,
  ) async {
    final assetMap = {for (final asset in assets) asset.id: asset};

    final similarGroupIds = await _hashService.findSimilarGroups(
      assets.map((asset) => asset.id).toList(),
      threshold: _visionDistanceThreshold,
    );

    return similarGroupIds
        .map(
          (ids) =>
              ids.map((id) => assetMap[id]).whereType<AssetEntity>().toList(),
        )
        .where((group) => group.length > 1)
        .toList();
  }

  List<AssetEntity> _sortAssets(List<AssetEntity> assets) {
    final sorted = [...assets];

    sorted.sort((a, b) {
      final dateCompare = a.createDateTime.compareTo(b.createDateTime);
      if (dateCompare != 0) return dateCompare;

      return a.id.compareTo(b.id);
    });

    return sorted;
  }
}
