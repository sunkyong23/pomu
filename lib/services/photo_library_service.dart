import 'package:photo_manager/photo_manager.dart';

class PhotoLibraryService {
  static const bool debugMode = true;
  static const int debugLimit = 30;

  Future<List<AssetEntity>> loadRecentPhotos({
    int limit = 500,
    bool ignoreDebugLimit = false,
  }) async {
    final filterOption = FilterOptionGroup(
      orders: [
        const OrderOption(
          type: OrderOptionType.createDate,
          asc: false, // 최신순
        ),
      ],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      return [];
    }

    final recentAlbum = albums.first;

    final actualLimit = debugMode && !ignoreDebugLimit ? debugLimit : limit;

    final photos = await recentAlbum.getAssetListPaged(
      page: 0,
      size: actualLimit,
    );

    print('📸 사진 ${photos.length}장 불러옴 / limit: $actualLimit');

    return photos;
  }

  Future<List<AssetEntity>> loadPhotosForDateRange({int limit = 5000}) async {
    return loadRecentPhotos(limit: limit, ignoreDebugLimit: true);
  }

  Future<List<AssetEntity>> loadPhotosAfter(DateTime? date) async {
    if (debugMode) {
      // 실기기 테스트용: lastScanAt 무시하고 항상 최근 30장
      return loadRecentPhotos();
    }

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
