import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_category.dart';
import 'album_service.dart';
import 'photo_library_service.dart';

import 'ai/ai_service.dart';

class ScanResult {
  final List<AssetEntity> photos;
  final Map<PhotoCategory, List<AssetEntity>> categorizedPhotos;

  const ScanResult({required this.photos, required this.categorizedPhotos});

  int get totalCount => photos.length;

  int get albumCount => categorizedPhotos.length;
}

class ScanService {
  static const _lastScanKey = 'last_scan_date';

  final PhotoLibraryService _photoLibraryService = PhotoLibraryService();
  final AIService _aiService = AIService();
  final AlbumService _albumService = AlbumService();

  Future<void> saveLastScan() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_lastScanKey, DateTime.now().toIso8601String());
  }

  Future<void> resetLastScan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastScanKey);
  }

  Future<DateTime?> getLastScan() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(_lastScanKey);

    if (value == null) return null;

    return DateTime.tryParse(value);
  }

  Future<List<AssetEntity>> loadNewPhotos() async {
    final lastScan = await getLastScan();

    return _photoLibraryService.loadPhotosAfter(lastScan);
  }

  Future<ScanResult> startOrganizing() async {
    final photos = await loadNewPhotos();

    print('🚀 정리 시작: ${photos.length}장');

    final categorizedPhotos = await _aiService.analyzePhotos(photos);

    print('📦 분류 완료: ${categorizedPhotos.length}개 카테고리');

    await _albumService.createAlbumsForCategories(categorizedPhotos);

    if (!PhotoLibraryService.debugMode) {
      await saveLastScan();
      print('💾 마지막 스캔 시간 저장 완료');
    } else {
      print('🧪 Debug mode: 마지막 스캔 시간 저장 생략');
    }

    return ScanResult(photos: photos, categorizedPhotos: categorizedPhotos);
  }
}
