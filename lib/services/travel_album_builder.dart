import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/album_definition.dart';
import 'album_service.dart';
import 'photo_library_service.dart';

class TravelAlbumBuilder {
  final PhotoLibraryService _photoLibraryService = PhotoLibraryService();
  final AlbumService _albumService = AlbumService();

  Future<AlbumDefinition> buildTravelAlbum({
    required String albumName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final assets = await _loadAssetsInDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    return AlbumDefinition(
      id: _buildId(albumName, startDate, endDate),
      albumName: albumName,
      photos: assets,
      type: AlbumDefinitionType.travel,
    );
  }

  Future<void> createTravelAlbum({
    required String albumName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final album = await buildTravelAlbum(
      albumName: albumName,
      startDate: startDate,
      endDate: endDate,
    );

    await _albumService.createAlbums([album]);
  }

  Future<List<AssetEntity>> _loadAssetsInDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final assets = await _photoLibraryService.loadAssetsForDateRange(
      startDate: startDate,
      endDate: endDate,
      limit: 5000,
    );

    assets.sort((a, b) {
      final dateCompare = a.createDateTime.compareTo(b.createDateTime);

      if (dateCompare != 0) {
        return dateCompare;
      }

      return a.id.compareTo(b.id);
    });

    debugPrint('🕒 기간·시간 앨범 정렬 완료: ${assets.length}개');

    return assets;
  }

  String _buildId(String albumName, DateTime startDate, DateTime endDate) {
    final safeName = albumName
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9가-힣_-]'), '');

    String formatDateTime(DateTime date) {
      return '${date.year}'
          '${date.month.toString().padLeft(2, '0')}'
          '${date.day.toString().padLeft(2, '0')}'
          '${date.hour.toString().padLeft(2, '0')}'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'travel_${formatDateTime(startDate)}_'
        '${formatDateTime(endDate)}_$safeName';
  }
}
