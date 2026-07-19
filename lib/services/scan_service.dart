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

  Future<List<AssetEntity>> loadNewPhotos() async {
    final lastScan = await getLastScan();
    return _photoLibraryService.loadPhotosAfter(lastScan);
  }

  Future<ScanResult> startOrganizing({ScanProgressCallback? onProgress}) async {
    final scanStartedAt = DateTime.now();

    onProgress?.call(const ScanProgress(stage: ScanStage.loadingPhotos));

    final photos = await loadNewPhotos();
    final total = photos.length;

    _log('🚀 정리 시작: $total장');

    if (photos.isEmpty) {
      if (!PhotoLibraryService.debugMode) {
        await saveLastScan(scanStartedAt);
      }

      onProgress?.call(const ScanProgress(stage: ScanStage.complete));

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
        completed: total,
        total: total,
      ),
    );

    if (albums.isNotEmpty) {
      await _albumService.createAlbums(albums);
    }

    if (!PhotoLibraryService.debugMode) {
      await saveLastScan(scanStartedAt);
      _log('💾 마지막 스캔 시간 저장 완료');
    } else {
      _log('🧪 Debug mode: 마지막 스캔 시간 저장 생략');
    }

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
