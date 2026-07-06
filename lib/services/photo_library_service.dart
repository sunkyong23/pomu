import 'package:photo_manager/photo_manager.dart';

class PhotoLibraryService {
  static const bool debugMode = true;
  static const int debugLimit = 1000;

  Future<List<AssetEntity>> loadRecentPhotos({
    int limit = 500,
    bool ignoreDebugLimit = false,
  }) async {
    final filterOption = _createNewestFirstFilter();

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      return [];
    }

    final actualLimit = debugMode && !ignoreDebugLimit ? debugLimit : limit;

    final photos = await albums.first.getAssetListPaged(
      page: 0,
      size: actualLimit,
    );

    print('📸 사진 ${photos.length}장 불러옴 / limit: $actualLimit');

    return photos;
  }

  Future<List<AssetEntity>> loadAssetsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5000,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final filterOption = FilterOptionGroup(
      createTimeCond: DateTimeCond(min: start, max: end),
      orders: [
        const OrderOption(
          type: OrderOptionType.createDate,
          asc: true, // 여행 앨범은 오래된 순
        ),
      ],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      return [];
    }

    final assets = await albums.first.getAssetListPaged(page: 0, size: limit);

    print(
      '📷+🎥 기간 Asset ${assets.length}개 불러옴 / '
      '${start.year}.${start.month}.${start.day} ~ '
      '${end.year}.${end.month}.${end.day} / limit: $limit',
    );

    return assets;
  }

  Future<List<AssetEntity>> loadPhotosForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5000,
  }) async {
    final assets = await loadAssetsForDateRange(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );

    return assets.where((asset) => asset.type == AssetType.image).toList();
  }

  Future<List<AssetEntity>> loadPhotosAfter(DateTime? date) async {
    if (debugMode) {
      // 실기기 테스트용: lastScanAt 무시하고 debugLimit 만큼 분석
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

  FilterOptionGroup _createNewestFirstFilter() {
    return FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );
  }
}
