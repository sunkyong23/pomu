import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../l10n/app_localizations.dart';

import '../../core/widgets/buttons/pomu_delete_action_row.dart';

extension _ScreenshotCleanupL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class ScreenshotCleanupScreen extends StatefulWidget {
  const ScreenshotCleanupScreen({super.key});

  @override
  State<ScreenshotCleanupScreen> createState() =>
      _ScreenshotCleanupScreenState();
}

class _ScreenshotCleanupScreenState extends State<ScreenshotCleanupScreen> {
  static const int _pageSize = 300;
  static const int _selectionResolvePageSize = 500;
  static const int _maxThumbnailCacheEntries = 72;
  static const int _maxExactSizeCalculationCount = 100;
  static const int _maxDeletePreviewThumbnails = 30;
  static const double _loadMoreThreshold = 900;

  final ScrollController _scrollController = ScrollController();
  final List<AssetEntity> _screenshots = [];
  final Set<String> _loadedAssetIds = {};
  final Set<String> _selectedAssetIds = {};
  final Set<String> _deselectedAssetIds = {};
  final Map<String, Future<Uint8List?>> _thumbnailFutures = {};

  AssetPathEntity? _screenshotAlbum;

  int _totalScreenshotCount = 0;
  int _nextPage = 0;

  bool _selectAllMode = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isPreparingDelete = false;
  bool _isDeleting = false;
  bool _permissionDenied = false;
  bool _limitedAccess = false;
  bool _hasMore = false;

  bool get _isBusy => _isDeleting || _isPreparingDelete;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadScreenshots();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _thumbnailFutures.clear();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMore) {
      return;
    }

    if (_scrollController.position.extentAfter < _loadMoreThreshold) {
      _loadMoreScreenshots();
    }
  }

  Future<Uint8List?> _getThumbnailFuture(AssetEntity asset) {
    final cached = _thumbnailFutures.remove(asset.id);

    if (cached != null) {
      _thumbnailFutures[asset.id] = cached;
      return cached;
    }

    final future = asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
      quality: 80,
    );

    _thumbnailFutures[asset.id] = future;

    while (_thumbnailFutures.length > _maxThumbnailCacheEntries) {
      _thumbnailFutures.remove(_thumbnailFutures.keys.first);
    }

    return future;
  }

  Future<void> _loadScreenshots() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _isLoadingMore = false;
    });

    final permissionState = await PhotoManager.requestPermissionExtend();

    if (!permissionState.hasAccess) {
      if (!mounted) return;

      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
      return;
    }

    _limitedAccess = permissionState == PermissionState.limited;

    try {
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: false,
        onlyAll: false,
        filterOption: FilterOptionGroup(
          orders: const [
            OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
        pathFilterOption: const PMPathFilter(
          darwin: PMDarwinPathFilter(
            type: [PMDarwinAssetCollectionType.smartAlbum],
            subType: [PMDarwinAssetCollectionSubtype.smartAlbumScreenshots],
          ),
        ),
      );

      if (paths.isEmpty) {
        if (!mounted) return;

        setState(() {
          _screenshotAlbum = null;
          _totalScreenshotCount = 0;
          _nextPage = 0;
          _hasMore = false;
          _screenshots.clear();
          _loadedAssetIds.clear();
          _thumbnailFutures.clear();
          _clearSelection();
          _isLoading = false;
        });
        return;
      }

      final screenshotAlbum = paths.first;
      final totalCount = await screenshotAlbum.assetCountAsync;
      final firstPage = totalCount == 0
          ? <AssetEntity>[]
          : await screenshotAlbum.getAssetListPaged(page: 0, size: _pageSize);

      if (!mounted) return;

      setState(() {
        _screenshotAlbum = screenshotAlbum;
        _totalScreenshotCount = totalCount;
        _nextPage = 1;

        _screenshots
          ..clear()
          ..addAll(firstPage);

        _loadedAssetIds
          ..clear()
          ..addAll(firstPage.map((asset) => asset.id));

        _thumbnailFutures.clear();
        _clearSelection();

        _hasMore = _screenshots.length < _totalScreenshotCount;
        _isLoading = false;
      });

      debugPrint(
        '📸 스크린샷 $_totalScreenshotCount장 중 '
        '${_screenshots.length}장 첫 페이지 로딩 완료',
      );
    } catch (error, stackTrace) {
      debugPrint('❌ 스크린샷 불러오기 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      _showSnackBar(context.l10n.screenshotLoadFailed);
    }
  }

  Future<void> _loadMoreScreenshots() async {
    final album = _screenshotAlbum;

    if (album == null || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final pageAssets = await album.getAssetListPaged(
        page: _nextPage,
        size: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        for (final asset in pageAssets) {
          if (_loadedAssetIds.add(asset.id)) {
            _screenshots.add(asset);
          }
        }

        _nextPage++;
        _hasMore =
            pageAssets.isNotEmpty &&
            _screenshots.length < _totalScreenshotCount;
        _isLoadingMore = false;
      });
    } catch (error, stackTrace) {
      debugPrint('❌ 스크린샷 추가 로딩 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _clearSelection() {
    _selectedAssetIds.clear();
    _deselectedAssetIds.clear();
    _selectAllMode = false;
  }

  int get _selectedCount {
    if (_selectAllMode) {
      final count = _totalScreenshotCount - _deselectedAssetIds.length;
      return count < 0 ? 0 : count;
    }

    return _selectedAssetIds.length;
  }

  bool _isAssetSelected(AssetEntity asset) {
    if (_selectAllMode) {
      return !_deselectedAssetIds.contains(asset.id);
    }

    return _selectedAssetIds.contains(asset.id);
  }

  void _toggleSelection(AssetEntity asset) {
    if (_isBusy) return;

    setState(() {
      if (_selectAllMode) {
        if (_deselectedAssetIds.contains(asset.id)) {
          _deselectedAssetIds.remove(asset.id);
        } else {
          _deselectedAssetIds.add(asset.id);
        }
        return;
      }

      if (_selectedAssetIds.contains(asset.id)) {
        _selectedAssetIds.remove(asset.id);
      } else {
        _selectedAssetIds.add(asset.id);
      }
    });
  }

  void _toggleSelectAll() {
    if (_totalScreenshotCount == 0 || _isBusy) return;

    setState(() {
      if (_isAllSelected) {
        _clearSelection();
      } else {
        _selectAllMode = true;
        _selectedAssetIds.clear();
        _deselectedAssetIds.clear();
      }
    });
  }

  bool get _isAllSelected {
    return _totalScreenshotCount > 0 &&
        _selectAllMode &&
        _deselectedAssetIds.isEmpty;
  }

  Future<void> _openLimitedPhotoPicker() async {
    await PhotoManager.presentLimited(type: RequestType.image);
    if (!mounted) return;
    await _loadScreenshots();
  }

  Future<void> _openAppSettings() async {
    await PhotoManager.openSetting();
  }

  Future<_ScreenshotSelectionSnapshot> _resolveSelectionSnapshot() async {
    final selectedCount = _selectedCount;

    if (selectedCount <= 0) {
      return const _ScreenshotSelectionSnapshot.empty();
    }

    final shouldCalculateExactSize =
        selectedCount <= _maxExactSizeCalculationCount;
    final ids = <String>[];
    final previewAssets = <AssetEntity>[];
    final sizeAssets = <AssetEntity>[];

    void addAsset(AssetEntity asset) {
      ids.add(asset.id);

      if (previewAssets.length < _maxDeletePreviewThumbnails) {
        previewAssets.add(asset);
      }

      if (shouldCalculateExactSize) {
        sizeAssets.add(asset);
      }
    }

    if (!_selectAllMode) {
      for (final asset in _screenshots) {
        if (_selectedAssetIds.contains(asset.id)) {
          addAsset(asset);
        }
      }

      return _ScreenshotSelectionSnapshot(
        ids: ids,
        previewAssets: previewAssets,
        sizeAssets: sizeAssets,
      );
    }

    final album = _screenshotAlbum;
    if (album == null) {
      return const _ScreenshotSelectionSnapshot.empty();
    }

    var page = 0;
    var scannedCount = 0;

    while (scannedCount < _totalScreenshotCount) {
      final pageAssets = await album.getAssetListPaged(
        page: page,
        size: _selectionResolvePageSize,
      );

      if (pageAssets.isEmpty) break;

      scannedCount += pageAssets.length;
      page++;

      for (final asset in pageAssets) {
        if (!_deselectedAssetIds.contains(asset.id)) {
          addAsset(asset);
        }
      }
    }

    return _ScreenshotSelectionSnapshot(
      ids: ids,
      previewAssets: previewAssets,
      sizeAssets: sizeAssets,
    );
  }

  Future<void> _showDeletePreview() async {
    if (_selectedCount == 0 || _isBusy) return;

    setState(() {
      _isPreparingDelete = true;
    });

    try {
      final snapshot = await _resolveSelectionSnapshot();

      if (!mounted) return;

      if (snapshot.ids.isEmpty) {
        setState(() {
          _isPreparingDelete = false;
          _clearSelection();
        });
        return;
      }

      final totalBytes = snapshot.sizeAssets.isEmpty
          ? 0
          : await _calculateTotalFileSize(snapshot.sizeAssets);

      if (!mounted) return;

      setState(() {
        _isPreparingDelete = false;
      });

      final readableSize = _formatBytes(context, totalBytes);
      final hiddenPreviewCount =
          snapshot.ids.length - snapshot.previewAssets.length;

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) {
          return Container(
            padding: const EdgeInsets.fromLTRB(
              PomuSpacing.lg,
              PomuSpacing.md,
              PomuSpacing.lg,
              PomuSpacing.lg,
            ),
            decoration: const BoxDecoration(
              color: PomuColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: PomuColors.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: PomuSpacing.lg),
                  Text(
                    sheetContext.l10n.screenshotDeletePreparationTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: PomuColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sheetContext.l10n.screenshotDeleteReview(
                      snapshot.ids.length,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: PomuColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: PomuSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(PomuSpacing.md),
                    decoration: BoxDecoration(
                      color: PomuColors.primaryLight,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storage_rounded,
                          color: PomuColors.primary,
                        ),
                        const SizedBox(width: PomuSpacing.sm),
                        Expanded(
                          child: Text(
                            sheetContext.l10n.estimatedSpace(readableSize),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: PomuColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PomuSpacing.md),
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          snapshot.previewAssets.length +
                          (hiddenPreviewCount > 0 ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: PomuSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index < snapshot.previewAssets.length) {
                          return _DeletePreviewThumbnail(
                            asset: snapshot.previewAssets[index],
                          );
                        }

                        return _MorePreviewCount(count: hiddenPreviewCount);
                      },
                    ),
                  ),
                  const SizedBox(height: PomuSpacing.lg),
                  Text(
                    sheetContext.l10n.screenshotMoveToRecentlyDeleted,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: PomuColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: PomuSpacing.md),
                  PomuDeleteActionRow(
                    cancelLabel: sheetContext.l10n.cancel,
                    deleteLabel: sheetContext.l10n.deleteCount(
                      snapshot.ids.length,
                    ),
                    onCancel: () {
                      Navigator.of(sheetContext).pop();
                    },
                    onDelete: () async {
                      Navigator.of(sheetContext).pop();
                      await _deleteSelectedIds(snapshot.ids);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error, stackTrace) {
      debugPrint('❌ 삭제 대상 준비 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isPreparingDelete = false;
      });
      _showSnackBar(context.l10n.screenshotDeleteFailed);
    }
  }

  Future<void> _deleteSelectedIds(List<String> requestedIds) async {
    if (requestedIds.isEmpty || _isBusy) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final deletedIds = await PhotoManager.editor.deleteWithIds(requestedIds);

      if (!mounted) return;

      if (deletedIds.isEmpty) {
        _showSnackBar(context.l10n.deleteCanceledOrFailed);
        setState(() {
          _isDeleting = false;
        });
        return;
      }

      setState(() {
        _isDeleting = false;
        _clearSelection();
      });

      _showSnackBar(context.l10n.screenshotDeletedSuccess(deletedIds.length));

      await _loadScreenshots();
    } catch (error, stackTrace) {
      debugPrint('❌ 스크린샷 삭제 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });
      _showSnackBar(context.l10n.screenshotDeleteFailed);
    }
  }

  Future<int> _calculateTotalFileSize(List<AssetEntity> assets) async {
    var totalBytes = 0;

    for (final asset in assets) {
      try {
        final file = await asset.file;
        if (file == null) continue;
        totalBytes += await file.length();
      } catch (error) {
        debugPrint('⚠️ 파일 크기 확인 실패: ${asset.id} / $error');
      }
    }

    return totalBytes;
  }

  String _formatBytes(BuildContext context, int bytes) {
    if (bytes <= 0) {
      return context.l10n.unableToCheckSize;
    }

    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)}KB';
    }

    final mb = kb / 1024;
    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)}MB';
    }

    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)}GB';
  }

  void _showPhotoPreview(AssetEntity asset) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: FutureBuilder<Uint8List?>(
                    future: asset.thumbnailDataWithSize(
                      const ThumbnailSize(1800, 1800),
                      quality: 95,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const CircularProgressIndicator(
                          color: Colors.white,
                        );
                      }

                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: PomuColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      appBar: AppBar(
        backgroundColor: PomuColors.background,
        elevation: 0,
        title: Text(
          context.l10n.homeScreenshotCleanupTitle,
          style: const TextStyle(
            color: PomuColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (!_isLoading && _totalScreenshotCount > 0)
            TextButton(
              onPressed: _isBusy ? null : _toggleSelectAll,
              child: Text(
                _isAllSelected
                    ? context.l10n.screenshotDeselectAll
                    : context.l10n.screenshotSelectAll,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: PomuColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: PomuColors.primary),
      );
    }

    if (_permissionDenied) {
      return _PermissionDeniedView(onOpenSettings: _openAppSettings);
    }

    return RefreshIndicator(
      color: PomuColors.primary,
      onRefresh: _loadScreenshots,
      child: CustomScrollView(
        controller: _scrollController,
        scrollCacheExtent: const ScrollCacheExtent.pixels(700),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              PomuSpacing.lg,
              PomuSpacing.md,
              PomuSpacing.lg,
              PomuSpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: _ScreenshotHeaderCard(
                totalCount: _totalScreenshotCount,
                selectedCount: _selectedCount,
              ),
            ),
          ),
          if (_limitedAccess)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PomuSpacing.lg,
                0,
                PomuSpacing.lg,
                PomuSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: _LimitedAccessCard(onTap: _openLimitedPhotoPicker),
              ),
            ),
          if (_totalScreenshotCount == 0 || _screenshots.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyScreenshotView(),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PomuSpacing.lg,
                0,
                PomuSpacing.lg,
                0,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final asset = _screenshots[index];
                  final isSelected = _isAssetSelected(asset);

                  return _ScreenshotTile(
                    asset: asset,
                    thumbnailFuture: _getThumbnailFuture(asset),
                    isSelected: isSelected,
                    onTap: () => _toggleSelection(asset),
                    onLongPress: () => _showPhotoPreview(asset),
                  );
                }, childCount: _screenshots.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 1,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: _hasMore || _isLoadingMore ? 78 : 130,
                child: Center(
                  child: _isLoadingMore
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: PomuColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context) {
    if (_isLoading || _permissionDenied || _totalScreenshotCount == 0) {
      return null;
    }

    final selectedCount = _selectedCount;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          PomuSpacing.lg,
          PomuSpacing.sm,
          PomuSpacing.lg,
          PomuSpacing.md,
        ),
        decoration: BoxDecoration(
          color: PomuColors.surface,
          border: Border(top: BorderSide(color: PomuColors.divider)),
        ),
        child: ElevatedButton.icon(
          onPressed: selectedCount == 0 || _isBusy ? null : _showDeletePreview,
          icon: _isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.delete_outline_rounded),
          label: Text(
            _isDeleting
                ? context.l10n.deleting
                : selectedCount == 0
                ? context.l10n.screenshotSelectToDelete
                : context.l10n.screenshotDeleteSelected(selectedCount),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: PomuColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: PomuColors.divider,
            disabledForegroundColor: PomuColors.textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenshotSelectionSnapshot {
  final List<String> ids;
  final List<AssetEntity> previewAssets;
  final List<AssetEntity> sizeAssets;

  const _ScreenshotSelectionSnapshot({
    required this.ids,
    required this.previewAssets,
    required this.sizeAssets,
  });

  const _ScreenshotSelectionSnapshot.empty()
    : ids = const [],
      previewAssets = const [],
      sizeAssets = const [];
}

class _ScreenshotHeaderCard extends StatelessWidget {
  final int totalCount;
  final int selectedCount;
  const _ScreenshotHeaderCard({
    required this.totalCount,
    required this.selectedCount,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PomuColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.screenshot_rounded,
              color: PomuColors.primary,
            ),
          ),
          const SizedBox(width: PomuSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.screenshotTotalCount(totalCount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedCount == 0
                      ? context.l10n.screenshotSelectToDeleteWithPeriod
                      : context.l10n.screenshotSelectedCount(selectedCount),
                  style: const TextStyle(
                    fontSize: 13,
                    color: PomuColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitedAccessCard extends StatelessWidget {
  final VoidCallback onTap;
  const _LimitedAccessCard({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PomuSpacing.md),
      decoration: BoxDecoration(
        color: PomuColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: PomuColors.primary),
          const SizedBox(width: PomuSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.screenshotLimitedAccessDescription,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: PomuColors.textPrimary,
              ),
            ),
          ),
          TextButton(onPressed: onTap, child: Text(context.l10n.addPhotos)),
        ],
      ),
    );
  }
}

class _ScreenshotTile extends StatelessWidget {
  final AssetEntity asset;
  final Future<Uint8List?> thumbnailFuture;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _ScreenshotTile({
    required this.asset,
    required this.thumbnailFuture,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<Uint8List?>(
              future: thumbnailFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Container(color: PomuColors.primaryLight);
                }
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                );
              },
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? PomuColors.primary.withValues(alpha: 0.24)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? PomuColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          Positioned(
            right: 7,
            top: 7,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: isSelected
                    ? PomuColors.primary
                    : Colors.black.withValues(alpha: 0.38),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletePreviewThumbnail extends StatelessWidget {
  final AssetEntity asset;
  const _DeletePreviewThumbnail({required this.asset});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: FutureBuilder<Uint8List?>(
        future: asset.thumbnailDataWithSize(const ThumbnailSize(180, 180)),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Container(
              width: 88,
              height: 88,
              color: PomuColors.primaryLight,
            );
          }
          return Image.memory(
            snapshot.data!,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}

class _MorePreviewCount extends StatelessWidget {
  final int count;

  const _MorePreviewCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PomuColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: PomuColors.primary,
        ),
      ),
    );
  }
}

class _EmptyScreenshotView extends StatelessWidget {
  const _EmptyScreenshotView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PomuSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: PomuColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 38,
                color: PomuColors.primary,
              ),
            ),
            const SizedBox(height: PomuSpacing.md),
            Text(
              context.l10n.screenshotEmptyTitle,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: PomuColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.screenshotEmptyDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: PomuColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _PermissionDeniedView({required this.onOpenSettings});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PomuSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 58,
              color: PomuColors.primary,
            ),
            const SizedBox(height: PomuSpacing.md),
            Text(
              context.l10n.photoPermissionRequiredTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: PomuColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.screenshotPermissionDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: PomuColors.textSecondary,
              ),
            ),
            const SizedBox(height: PomuSpacing.lg),
            ElevatedButton(
              onPressed: onOpenSettings,
              child: Text(context.l10n.openSettings),
            ),
          ],
        ),
      ),
    );
  }
}
