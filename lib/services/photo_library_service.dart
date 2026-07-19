import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoLibraryService {
  static const bool debugMode = kDebugMode;
  static const int _defaultPageSize = 500;

  /// 최신 사진 일부만 필요한 화면에서 사용합니다.
  ///
  /// [ignoreDebugLimit]는 기존 호출부 호환을 위해 남겨둔 값이며,
  /// 이제 디버그 빌드에서도 별도의 사진 개수 제한을 적용하지 않습니다.
  Future<List<AssetEntity>> loadRecentPhotos({
    int limit = 500,
    bool ignoreDebugLimit = false,
  }) async {
    final safeLimit = limit <= 0 ? 1 : limit;
    final albums = await _getAllPhotoAlbums();

    if (albums.isEmpty) {
      debugPrint('📭 사진 보관함에서 사진을 찾지 못했어요.');
      return const <AssetEntity>[];
    }

    final photos = await albums.first.getAssetListPaged(
      page: 0,
      size: safeLimit,
    );

    debugPrint(
      '📸 최신 사진 ${photos.length}장 불러오기 완료 '
      '/ 요청 개수: $safeLimit',
    );

    return photos;
  }

  /// 사진 보관함의 모든 이미지를 페이지 단위로 끝까지 불러옵니다.
  ///
  /// 디버그·릴리스 빌드 모두 사진 개수 제한이 없습니다.
  Future<List<AssetEntity>> loadAllPhotos({
    int pageSize = _defaultPageSize,
    void Function(int loaded, int total)? onProgress,
  }) async {
    final safePageSize = _normalizePageSize(pageSize);
    final albums = await _getAllPhotoAlbums();

    if (albums.isEmpty) {
      onProgress?.call(0, 0);
      debugPrint('📭 사진 보관함에서 사진을 찾지 못했어요.');
      return const <AssetEntity>[];
    }

    final album = albums.first;
    final totalCount = await album.assetCountAsync;

    return _loadAllAssetsFromAlbum(
      album: album,
      totalCount: totalCount,
      pageSize: safePageSize,
      onProgress: onProgress,
      logName: '전체 사진',
    );
  }

  /// 선택한 기간·시간에 해당하는 사진과 영상을 모두 불러옵니다.
  ///
  /// 기존 호출부와의 호환을 위해 매개변수 이름은 [limit]로 유지하지만,
  /// 이제 최대 개수 제한이 아니라 페이지 크기로만 사용합니다.
  /// 따라서 5,000개를 초과해도 마지막 페이지까지 모두 불러옵니다.
  Future<List<AssetEntity>> loadAssetsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = _defaultPageSize,
    void Function(int loaded, int total)? onProgress,
  }) async {
    if (endDate.isBefore(startDate)) {
      debugPrint(
        '⚠️ 잘못된 기간·시간 범위: '
        '${_formatDateTime(startDate)} ~ ${_formatDateTime(endDate)}',
      );

      onProgress?.call(0, 0);
      return const <AssetEntity>[];
    }

    final safePageSize = _normalizePageSize(limit);
    final filterOption = FilterOptionGroup(
      createTimeCond: DateTimeCond(min: startDate, max: endDate),
      orders: const <OrderOption>[
        OrderOption(type: OrderOptionType.createDate, asc: true),
      ],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: filterOption,
    );

    if (albums.isEmpty) {
      debugPrint(
        '📭 선택한 기간·시간에 사진이나 영상이 없어요 / '
        '${_formatDateTime(startDate)} ~ ${_formatDateTime(endDate)}',
      );

      onProgress?.call(0, 0);
      return const <AssetEntity>[];
    }

    final album = albums.first;
    final totalCount = await album.assetCountAsync;

    final assets = await _loadAllAssetsFromAlbum(
      album: album,
      totalCount: totalCount,
      pageSize: safePageSize,
      onProgress: onProgress,
      logName: '기간·시간 사진·영상',
    );

    debugPrint(
      '✅ 기간·시간 Asset ${assets.length}개 불러오기 완료 / '
      '${_formatDateTime(startDate)} ~ ${_formatDateTime(endDate)}',
    );

    return assets;
  }

  /// 선택한 기간·시간에 해당하는 사진만 모두 불러옵니다.
  Future<List<AssetEntity>> loadPhotosForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = _defaultPageSize,
    void Function(int loaded, int total)? onProgress,
  }) async {
    final assets = await loadAssetsForDateRange(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      onProgress: onProgress,
    );

    return assets
        .where((asset) => asset.type == AssetType.image)
        .toList(growable: false);
  }

  /// 마지막 분석 시점 이후에 생성된 사진을 반환합니다.
  ///
  /// [date]가 null이면 최초 분석이므로 전체 사진을 반환합니다.
  /// 디버그·릴리스 빌드 모두 동일하게 전체 보관함을 확인합니다.
  Future<List<AssetEntity>> loadPhotosAfter(
    DateTime? date, {
    int pageSize = _defaultPageSize,
    void Function(int loaded, int total)? onProgress,
  }) async {
    final photos = await loadAllPhotos(
      pageSize: pageSize,
      onProgress: onProgress,
    );

    if (date == null) {
      debugPrint('📸 최초 AI 분석 대상: 전체 사진 ${photos.length}장');
      return photos;
    }

    final filteredPhotos = photos
        .where((photo) {
          return photo.createDateTime.isAfter(date);
        })
        .toList(growable: false);

    debugPrint(
      '📸 마지막 분석 이후 새 사진 ${filteredPhotos.length}장 / '
      '기준: ${_formatDateTime(date)}',
    );

    return filteredPhotos;
  }

  /// 현재 접근 가능한 전체 사진 개수를 반환합니다.
  ///
  /// 사진 객체를 전부 메모리에 올리지 않고 앨범의 개수만 조회합니다.
  Future<int> getRecentPhotoCount() async {
    final albums = await _getAllPhotoAlbums();

    if (albums.isEmpty) {
      return 0;
    }

    final totalCount = await albums.first.assetCountAsync;
    debugPrint('📊 현재 접근 가능한 전체 사진 수: $totalCount장');

    return totalCount;
  }

  Future<List<AssetPathEntity>> _getAllPhotoAlbums() {
    return PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: _createNewestFirstFilter(),
    );
  }

  Future<List<AssetEntity>> _loadAllAssetsFromAlbum({
    required AssetPathEntity album,
    required int totalCount,
    required int pageSize,
    required String logName,
    void Function(int loaded, int total)? onProgress,
  }) async {
    if (totalCount <= 0) {
      onProgress?.call(0, 0);
      return const <AssetEntity>[];
    }

    final assets = <AssetEntity>[];
    final seenAssetIds = <String>{};
    var page = 0;

    onProgress?.call(0, totalCount);

    while (assets.length < totalCount) {
      final pageAssets = await album.getAssetListPaged(
        page: page,
        size: pageSize,
      );

      if (pageAssets.isEmpty) {
        debugPrint(
          '⚠️ $logName 페이지가 비어 있어 불러오기를 종료합니다. '
          '/ page: $page '
          '/ loaded: ${assets.length} '
          '/ total: $totalCount',
        );
        break;
      }

      var addedCount = 0;

      for (final asset in pageAssets) {
        if (seenAssetIds.add(asset.id)) {
          assets.add(asset);
          addedCount++;
        }
      }

      final loadedCount = assets.length > totalCount
          ? totalCount
          : assets.length;

      onProgress?.call(loadedCount, totalCount);

      debugPrint(
        '📸 $logName 불러오는 중 '
        '$loadedCount / $totalCount '
        '(page: $page, pageSize: $pageSize)',
      );

      if (addedCount == 0) {
        debugPrint(
          '⚠️ $logName에서 새 Asset이 추가되지 않아 '
          '무한 반복을 방지하고 종료합니다. / page: $page',
        );
        break;
      }

      page++;
    }

    debugPrint(
      '✅ $logName ${assets.length}개 불러오기 완료 '
      '/ 조회 당시 전체 개수: $totalCount',
    );

    return List<AssetEntity>.unmodifiable(assets);
  }

  int _normalizePageSize(int pageSize) {
    return pageSize <= 0 ? _defaultPageSize : pageSize;
  }

  FilterOptionGroup _createNewestFirstFilter() {
    return FilterOptionGroup(
      orders: const <OrderOption>[
        OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
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
