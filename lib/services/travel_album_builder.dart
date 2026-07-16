import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/album_definition.dart';
import 'album_service.dart';
import 'photo_library_service.dart';

class TravelAlbumBuilder {
  final PhotoLibraryService _photoLibraryService;
  final AlbumService _albumService;

  TravelAlbumBuilder({
    PhotoLibraryService? photoLibraryService,
    AlbumService? albumService,
  }) : _photoLibraryService = photoLibraryService ?? PhotoLibraryService(),
       _albumService = albumService ?? AlbumService();

  Future<AlbumDefinition> buildTravelAlbum({
    required String albumName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedName = albumName.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        albumName,
        'albumName',
        'Album name must not be empty.',
      );
    }

    if (endDate.isBefore(startDate)) {
      throw ArgumentError('endDate must be equal to or later than startDate.');
    }

    final assets = await _loadAssetsInDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    return AlbumDefinition(
      id: _buildId(normalizedName, startDate, endDate),
      albumName: normalizedName,
      photos: List<AssetEntity>.unmodifiable(assets),
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

    if (album.photos.isEmpty) {
      return;
    }

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

    final sortedAssets = List<AssetEntity>.of(assets)
      ..sort((a, b) {
        final dateCompare = a.createDateTime.compareTo(b.createDateTime);

        if (dateCompare != 0) {
          return dateCompare;
        }

        return a.id.compareTo(b.id);
      });

    _log('🕒 기간·시간 앨범 정렬 완료: ${sortedAssets.length}개');

    return sortedAssets;
  }

  String _buildId(String albumName, DateTime startDate, DateTime endDate) {
    final safeName = albumName
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\p{L}\p{N}_-]', unicode: true), '');

    final normalizedSafeName = safeName.isEmpty ? 'album' : safeName;

    return 'travel_${_formatDateTime(startDate)}_'
        '${_formatDateTime(endDate)}_$normalizedSafeName';
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
