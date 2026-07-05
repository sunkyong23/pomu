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
    final photos = await _loadPhotosInDateRange(
      startDate: startDate,
      endDate: endDate,
    );

    return AlbumDefinition(
      id: _buildId(albumName, startDate, endDate),
      albumName: albumName,
      photos: photos,
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

  Future<List<AssetEntity>> _loadPhotosInDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final photos = await _photoLibraryService.loadPhotosForDateRange(
      limit: 5000,
    );

    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    return photos.where((photo) {
      final createdAt = photo.createDateTime;

      return createdAt.isAtSameMomentAs(start) ||
          createdAt.isAtSameMomentAs(end) ||
          (createdAt.isAfter(start) && createdAt.isBefore(end));
    }).toList();
  }

  String _buildId(String albumName, DateTime startDate, DateTime endDate) {
    final safeName = albumName
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9가-힣_ -]'), '');

    return 'travel_${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}_'
        '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}_$safeName';
  }
}
