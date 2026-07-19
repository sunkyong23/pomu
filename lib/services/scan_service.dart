import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_category.dart';
import 'ai/ai_service.dart';
import 'album_service.dart';
import 'photo_library_service.dart';

enum ScanStage { loadingPhotos, analyzingPhotos, creatingAlbums, complete }

class ScanProgress {
  final ScanStage stage;
  final int completed;
  final int total;

  const ScanProgress({required this.stage, this.completed = 0, this.total = 0});

  int get remaining {
    final value = total - completed;
    return value < 0 ? 0 : value;
  }

  double? get fraction {
    if (total <= 0) return null;
    return (completed / total).clamp(0.0, 1.0);
  }
}

typedef ScanProgressCallback = void Function(ScanProgress progress);

class ScanResult {
  final List<AssetEntity> photos;
  final Map<PhotoCategory, List<AssetEntity>> categorizedPhotos;

  const ScanResult({required this.photos, required this.categorizedPhotos});

  int get totalCount => photos.length;

  int get albumCount => categorizedPhotos.length;

  bool get isEmpty => photos.isEmpty;
}

class ScanService {
  static const String _lastScanKey = 'last_scan_date';

  final PhotoLibraryService _photoLibraryService;
  final AIService _aiService;
  final AlbumService _albumService;

  ScanService({
    PhotoLibraryService? photoLibraryService,
    AIService? aiService,
    AlbumService? albumService,
  }) : _photoLibraryService = photoLibraryService ?? PhotoLibraryService(),
       _aiService = aiService ?? AIService(),
       _albumService = albumService ?? AlbumService();

  Future<void> saveLastScan([DateTime? scannedAt]) async {
    final prefs = await SharedPreferences.getInstance();
    final value = (scannedAt ?? DateTime.now()).toIso8601String();

    await prefs.setString(_lastScanKey, value);
  }

  Future<void> resetLastScan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastScanKey);
  }

  Future<DateTime?> getLastScan() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastScanKey);

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  /// 최초 실행이면 전체 사진을, 이후 실행이면 마지막 성공 시점 이후의
  /// 새 사진만 불러옵니다.
  ///
  /// 사진 보관함 로딩 과정도 실제 개수 기준으로 진행률을 전달합니다.
  Future<List<AssetEntity>> loadNewPhotos({
    void Function(int loaded, int total)? onProgress,
  }) async {
    final lastScan = await getLastScan();

    return _photoLibraryService.loadPhotosAfter(
      lastScan,
      onProgress: onProgress,
    );
  }

  /// 사진 로딩 → AI 분석 → 앨범 생성의 전체 흐름을 실행합니다.
  ///
  /// 마지막 스캔 시간은 모든 과정이 정상적으로 완료된 뒤에만 저장합니다.
  /// 중간에 오류가 발생하면 저장하지 않으므로 다음 실행에서 누락 없이
  /// 다시 분석할 수 있습니다.
  Future<ScanResult> startOrganizing({ScanProgressCallback? onProgress}) async {
    final scanStartedAt = DateTime.now();

    onProgress?.call(
      const ScanProgress(
        stage: ScanStage.loadingPhotos,
        completed: 0,
        total: 0,
      ),
    );

    final photos = await loadNewPhotos(
      onProgress: (loaded, total) {
        onProgress?.call(
          ScanProgress(
            stage: ScanStage.loadingPhotos,
            completed: loaded,
            total: total,
          ),
        );
      },
    );

    final total = photos.length;

    _log('🚀 정리 시작: $total장');

    if (photos.isEmpty) {
      await saveLastScan(scanStartedAt);
      _log('💾 새 사진 없음: 마지막 스캔 시간 저장 완료');

      onProgress?.call(
        const ScanProgress(stage: ScanStage.complete, completed: 0, total: 0),
      );

      return const ScanResult(
        photos: <AssetEntity>[],
        categorizedPhotos: <PhotoCategory, List<AssetEntity>>{},
      );
    }

    onProgress?.call(
      ScanProgress(
        stage: ScanStage.analyzingPhotos,
        completed: 0,
        total: total,
      ),
    );

    final albums = await _aiService.analyzePhotosToAlbums(
      photos,
      onProgress: (completed, analysisTotal) {
        onProgress?.call(
          ScanProgress(
            stage: ScanStage.analyzingPhotos,
            completed: completed,
            total: analysisTotal,
          ),
        );
      },
    );

    _log('📦 앨범 생성 준비 완료: ${albums.length}개');

    onProgress?.call(
      ScanProgress(
        stage: ScanStage.creatingAlbums,
        completed: 0,
        total: albums.length,
      ),
    );

    if (albums.isNotEmpty) {
      await _albumService.createAlbums(albums);
    }

    // AI 분석과 앨범 생성이 모두 성공한 경우에만 저장합니다.
    // 디버그 빌드도 실제 사용자 흐름과 동일하게 동작합니다.
    await saveLastScan(scanStartedAt);
    _log('💾 마지막 스캔 시간 저장 완료: $scanStartedAt');

    final categorizedPhotos = <PhotoCategory, List<AssetEntity>>{
      for (final album in albums)
        if (album.category != null)
          album.category!: List<AssetEntity>.unmodifiable(album.photos),
    };

    final result = ScanResult(
      photos: List<AssetEntity>.unmodifiable(photos),
      categorizedPhotos: Map<PhotoCategory, List<AssetEntity>>.unmodifiable(
        categorizedPhotos,
      ),
    );

    onProgress?.call(
      ScanProgress(stage: ScanStage.complete, completed: total, total: total),
    );

    return result;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
