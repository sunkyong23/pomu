import 'package:photo_manager/photo_manager.dart';

class PhotoLibraryService {
  Future<List<AssetEntity>> loadRecentPhotos({int limit = 500}) async {
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);

    if (albums.isEmpty) {
      return [];
    }

    final recentAlbum = albums.first;

    return recentAlbum.getAssetListPaged(page: 0, size: limit);
  }

  Future<List<AssetEntity>> loadPhotosAfter(DateTime? date) async {
    final photos = await loadRecentPhotos(limit: 5000);

    if (date == null) {
      return photos;
    }

    return photos.where((photo) {
      return photo.createDateTime.isAfter(date);
    }).toList();
  }

  Future<int> getRecentPhotoCount() async {
    final photos = await loadRecentPhotos();
    return photos.length;
  }
}
