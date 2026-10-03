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
    void Function(int current, int total)? onProgress,
  }) async {
    final assets = await _photoLibraryService.loadAllPhotos();

    // 기존처럼 imageAssets 리스트를 한 번 더 만들지 않고
    // 이미지 자산만 바로 해상도 그룹에 넣어요.
    final resolutionGroups = <String, List<AssetEntity>>{};

    for (final asset in assets) {
      if (asset.type != AssetType.image) {
        continue;
      }

      final key = _buildResolutionKey(asset);
      (resolutionGroups[key] ??= <AssetEntity>[]).add(asset);
    }

    // 같은 해상도 사진이 1장뿐인 그룹은 애초에 중복 후보가 될 수 없으므로
    // 정렬/시간 클러스터링 자체를 하지 않아요.
    final timeCandidateGroups = <List<AssetEntity>>[];

    for (final groupAssets in resolutionGroups.values) {
      if (groupAssets.length <= 1) {
        continue;
      }

      final sortedAssets = _sortAssets(groupAssets);

      // 길이 2 이상인 후보 클러스터만 바로 추가합니다.
      _appendTimeCandidateGroups(sortedAssets, timeCandidateGroups);
    }

    // 해상도 그룹 Map은 여기 이후 필요 없어요.
    // 지역 변수라 메서드 진행 중 GC 대상이 될 수 있도록 더 이상 참조하지 않습니다.

    final duplicateGroups = <DuplicatePhotoGroup>[];
    final totalGroupCount = timeCandidateGroups.length;
    var completedGroupCount = 0;

    onProgress?.call(0, totalGroupCount);

    // IMPORTANT:
    // Vision 호출은 현재는 순차 처리 유지.
    // duplicate_hash_service.dart / Swift 구현을 확인하기 전에는
    // 무작정 병렬화하면 iCloud 다운로드, 메모리, VNRequest 동시 실행 문제로
    // 오히려 불안정해질 수 있어요.
    for (final candidateGroup in timeCandidateGroups) {
      final visuallySimilarGroups = await _filterVisuallySimilarGroups(
        candidateGroup,
      );

      completedGroupCount++;
      onProgress?.call(completedGroupCount, totalGroupCount);

      for (final group in visuallySimilarGroups) {
        if (group.length <= 1) {
          continue;
        }

        final firstAsset = group.first;
        final id =
            '${_buildResolutionKey(firstAsset)}_'
            '${firstAsset.createDateTime.millisecondsSinceEpoch}';

        duplicateGroups.add(DuplicatePhotoGroup(id: id, assets: group));
      }
    }

    duplicateGroups.sort((a, b) {
      final countCompare = b.count.compareTo(a.count);

      if (countCompare != 0) {
        return countCompare;
      }

      return b.assets.first.createDateTime.compareTo(
        a.assets.first.createDateTime,
      );
    });

    debugPrint(
      '🧹 중복 후보 그룹 ${duplicateGroups.length}개 발견 '
      '/ 시간 후보 $totalGroupCount개',
    );

    return duplicateGroups;
  }

  String _buildResolutionKey(AssetEntity asset) {
    return '${asset.width}x${asset.height}';
  }

  /// 정렬된 사진 목록에서 5초 이내로 이어지는 사진들만 묶고,
  /// 실제 후보가 될 수 있는 길이 2 이상의 그룹만 [output]에 추가해요.
  ///
  /// 기존처럼 1장짜리 cluster까지 임시 리스트에 만든 뒤 버리지 않아서
  /// 사진이 많은 라이브러리에서 불필요한 List 할당을 줄입니다.
  void _appendTimeCandidateGroups(
    List<AssetEntity> sortedAssets,
    List<List<AssetEntity>> output,
  ) {
    if (sortedAssets.length <= 1) {
      return;
    }

    var clusterStart = 0;

    for (var i = 1; i < sortedAssets.length; i++) {
      final previous = sortedAssets[i - 1];
      final current = sortedAssets[i];

      final diff = current.createDateTime.difference(previous.createDateTime);

      if (diff.abs() <= _duplicateTimeWindow) {
        continue;
      }

      final clusterLength = i - clusterStart;

      if (clusterLength > 1) {
        output.add(sortedAssets.sublist(clusterStart, i));
      }

      clusterStart = i;
    }

    final finalClusterLength = sortedAssets.length - clusterStart;

    if (finalClusterLength > 1) {
      output.add(sortedAssets.sublist(clusterStart));
    }
  }

  Future<List<List<AssetEntity>>> _filterVisuallySimilarGroups(
    List<AssetEntity> assets,
  ) async {
    if (assets.length <= 1) {
      return const <List<AssetEntity>>[];
    }

    final assetMap = <String, AssetEntity>{
      for (final asset in assets) asset.id: asset,
    };

    final assetIds = <String>[for (final asset in assets) asset.id];

    final similarGroupIds = await _hashService.findSimilarGroups(
      assetIds,
      threshold: _visionDistanceThreshold,
    );

    final result = <List<AssetEntity>>[];

    for (final ids in similarGroupIds) {
      if (ids.length <= 1) {
        continue;
      }

      final group = <AssetEntity>[];

      for (final id in ids) {
        final asset = assetMap[id];

        if (asset != null) {
          group.add(asset);
        }
      }

      if (group.length > 1) {
        result.add(group);
      }
    }

    return result;
  }

  List<AssetEntity> _sortAssets(List<AssetEntity> assets) {
    final sorted = List<AssetEntity>.of(assets);

    sorted.sort((a, b) {
      final dateCompare = a.createDateTime.compareTo(b.createDateTime);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return a.id.compareTo(b.id);
    });

    return sorted;
  }
}
