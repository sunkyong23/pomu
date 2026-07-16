import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_category.dart';
import 'ai/ai_service.dart';
import 'album_service.dart';
import 'photo_library_service.dart';

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

  Future<ScanResult> startOrganizing() async {
    final scanStartedAt = DateTime.now();
    final photos = await loadNewPhotos();

    _log('🚀 정리 시작: ${photos.length}장');

    if (photos.isEmpty) {
      if (!PhotoLibraryService.debugMode) {
        await saveLastScan(scanStartedAt);
      }

      return const ScanResult(
        photos: <AssetEntity>[],
        categorizedPhotos: <PhotoCategory, List<AssetEntity>>{},
      );
    }

    final albums = await _aiService.analyzePhotosToAlbums(photos);

    _log('📦 앨범 생성 준비 완료: ${albums.length}개');

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

    return ScanResult(
      photos: List<AssetEntity>.unmodifiable(photos),
      categorizedPhotos: Map<PhotoCategory, List<AssetEntity>>.unmodifiable(
        categorizedPhotos,
      ),
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
