import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/album_definition.dart';
import '../../models/photo_category.dart';
import '../../models/photo_tag.dart';
import '../album_settings_service.dart';
import 'category_mapper.dart';
import 'vision_service.dart';

typedef AIAnalysisProgressCallback = void Function(int completed, int total);

class AIService {
  final VisionService _visionService;
  final CategoryMapper _categoryMapper;
  final AlbumSettingsService _albumSettingsService;

  AIService({
    VisionService? visionService,
    CategoryMapper? categoryMapper,
    AlbumSettingsService? albumSettingsService,
  }) : _visionService = visionService ?? VisionService(),
       _categoryMapper = categoryMapper ?? CategoryMapper(),
       _albumSettingsService = albumSettingsService ?? AlbumSettingsService();

  /// 사진을 AI로 분석한 뒤, 카테고리별 Apple 사진 앨범 생성에 사용할
  /// [AlbumDefinition] 목록으로 변환합니다.
  Future<List<AlbumDefinition>> analyzePhotosToAlbums(
    List<AssetEntity> photos, {
    AIAnalysisProgressCallback? onProgress,
  }) async {
    final categorizedPhotos = await analyzePhotos(
      photos,
      onProgress: onProgress,
    );

    final albums = <AlbumDefinition>[];

    for (final entry in categorizedPhotos.entries) {
      final category = entry.key;
      final categoryPhotos = entry.value;

      if (categoryPhotos.isEmpty) {
        continue;
      }

      final albumName = await _albumSettingsService.getAlbumName(category);

      albums.add(
        AlbumDefinition(
          id: category.name,
          albumName: albumName,
          photos: List<AssetEntity>.unmodifiable(categoryPhotos),
          type: AlbumDefinitionType.aiCategory,
          category: category,
        ),
      );
    }

    return List<AlbumDefinition>.unmodifiable(albums);
  }

  /// 사진을 한 장씩 순차 분석합니다.
  ///
  /// 각 사진은 성공 여부와 관계없이 완료 수에 포함됩니다. Vision 분석 중
  /// 특정 사진에서 오류가 발생하면 해당 사진은 `other` 카테고리에 넣고,
  /// 전체 분석은 중단하지 않습니다.
  Future<Map<PhotoCategory, List<AssetEntity>>> analyzePhotos(
    List<AssetEntity> photos, {
    AIAnalysisProgressCallback? onProgress,
  }) async {
    final result = <PhotoCategory, List<AssetEntity>>{
      for (final category in PhotoCategory.values) category: <AssetEntity>[],
    };

    final total = photos.length;

    onProgress?.call(0, total);

    for (var index = 0; index < total; index++) {
      final photo = photos[index];
      final current = index + 1;

      try {
        _log('🔍 분석 시작 $current/$total: ${photo.id}');

        final labels = await _visionService.analyzePhoto(photo);

        _debugPrintLabels(photo.id, labels);

        final categories = _categoryMapper.mapLabels(labels);
        final tags = _categoryMapper.mapTags(labels);

        _log(
          '📁 최종 카테고리 $current/$total: '
          '${categories.map((category) => category.name).join(', ')}',
        );

        _debugPrintTags(photo.id, tags);

        if (categories.isEmpty) {
          result[PhotoCategory.other]!.add(photo);
        } else {
          for (final category in categories) {
            result[category]!.add(photo);
          }
        }
      } catch (error, stackTrace) {
        _log('⚠️ Vision failed $current/$total for ${photo.id}: $error');

        if (kDebugMode) {
          debugPrintStack(stackTrace: stackTrace);
        }

        result[PhotoCategory.other]!.add(photo);
      } finally {
        // 오류가 난 사진도 처리 완료로 계산해야 진행률이 멈추지 않습니다.
        onProgress?.call(current, total);
      }
    }

    result.removeWhere((_, photos) => photos.isEmpty);

    _log('✅ AI 분석 완료');

    for (final entry in result.entries) {
      _log(' - ${entry.key.name}: ${entry.value.length}장');
    }

    return Map<PhotoCategory, List<AssetEntity>>.unmodifiable(
      result.map(
        (category, categoryPhotos) =>
            MapEntry(category, List<AssetEntity>.unmodifiable(categoryPhotos)),
      ),
    );
  }

  void _debugPrintLabels(String id, List<VisionLabel> labels) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('📷 Photo $id');

    if (labels.isEmpty) {
      debugPrint(' - 라벨 없음');
      return;
    }

    for (final label in labels) {
      debugPrint(' - ${label.identifier}: ${label.confidence}');
    }
  }

  void _debugPrintTags(String id, List<PhotoTag> tags) {
    if (!kDebugMode) {
      return;
    }

    if (tags.isEmpty) {
      debugPrint('🏷️ 세부 태그 없음: $id');
      return;
    }

    debugPrint(
      '🏷️ 세부 태그 $id: '
      '${tags.map((tag) => tag.koreanName).join(', ')}',
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
