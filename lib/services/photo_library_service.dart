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

  Future<List<AssetEntity>> loadAllPhotos({
    int pageSize = 500,
    void Function(int loaded, int total)? onProgress,
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

    final album = albums.first;
    final totalCount = await album.assetCountAsync;

    final photos = <AssetEntity>[];
    var page = 0;

    onProgress?.call(0, totalCount);

    while (photos.length < totalCount) {
      final pageAssets = await album.getAssetListPaged(
        page: page,
        size: pageSize,
      );

      if (pageAssets.isEmpty) {
        break;
      }

      photos.addAll(pageAssets);

      final loadedCount = photos.length > totalCount
          ? totalCount
          : photos.length;

      onProgress?.call(loadedCount, totalCount);

      print(
        '📸 전체 사진 불러오는 중 '
        '$loadedCount / $totalCount '
        '(page: $page)',
      );

      page++;
    }

    print('✅ 전체 사진 ${photos.length}장 불러오기 완료');

    return photos;
  }

  Future<List<AssetEntity>> loadAssetsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5000,
  }) async {
    if (endDate.isBefore(startDate)) {
      print(
        '⚠️ 잘못된 기간·시간 범위: '
        '${_formatDateTime(startDate)} ~ ${_formatDateTime(endDate)}',
      );

      return [];
    }

    final filterOption = FilterOptionGroup(
      createTimeCond: DateTimeCond(min: startDate, max: endDate),
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: true)],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      print(
        '📭 선택한 기간·시간에 사진이나 영상이 없어요 / '
        '${_formatDateTime(startDate)} ~ ${_formatDateTime(endDate)}',
      );

      return [];
    }

    final assets = await albums.first.getAssetListPaged(page: 0, size: limit);

    print(
      '📷+🎥 기간·시간 Asset ${assets.length}개 불러옴 / '
      '${_formatDateTime(startDate)} ~ '
      '${_formatDateTime(endDate)} / '
      'limit: $limit',
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
      // 실기기 테스트용:
      // lastScanAt을 무시하고 debugLimit만큼 분석해요.
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

  String _formatDateTime(DateTime date) {
    return '${date.year}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }
}
