import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';

class ScreenshotCleanupScreen extends StatefulWidget {
  const ScreenshotCleanupScreen({super.key});

  @override
  State<ScreenshotCleanupScreen> createState() =>
      _ScreenshotCleanupScreenState();
}

class _ScreenshotCleanupScreenState extends State<ScreenshotCleanupScreen> {
  static const int _pageSize = 300;

  final List<AssetEntity> _screenshots = [];
  final Set<String> _selectedAssetIds = {};

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _permissionDenied = false;
  bool _limitedAccess = false;

  @override
  void initState() {
    super.initState();
    _loadScreenshots();
  }

  Future<void> _loadScreenshots() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
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
          _screenshots.clear();
          _selectedAssetIds.clear();
          _isLoading = false;
        });

        return;
      }

      final screenshotAlbum = paths.first;
      final totalCount = await screenshotAlbum.assetCountAsync;

      final loadedScreenshots = <AssetEntity>[];
      var page = 0;

      while (loadedScreenshots.length < totalCount) {
        final pageAssets = await screenshotAlbum.getAssetListPaged(
          page: page,
          size: _pageSize,
        );

        if (pageAssets.isEmpty) {
          break;
        }

        loadedScreenshots.addAll(pageAssets);
        page++;
      }

      if (!mounted) return;

      setState(() {
        _screenshots
          ..clear()
          ..addAll(loadedScreenshots);

        _selectedAssetIds.removeWhere(
          (id) => !_screenshots.any((asset) => asset.id == id),
        );

        _isLoading = false;
      });

      debugPrint('📸 스크린샷 ${_screenshots.length}장 불러오기 완료');
    } catch (error, stackTrace) {
      debugPrint('❌ 스크린샷 불러오기 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('스크린샷을 불러오지 못했어요.');
    }
  }

  void _toggleSelection(AssetEntity asset) {
    if (_isDeleting) return;

    setState(() {
      if (_selectedAssetIds.contains(asset.id)) {
        _selectedAssetIds.remove(asset.id);
      } else {
        _selectedAssetIds.add(asset.id);
      }
    });
  }

  void _toggleSelectAll() {
    if (_screenshots.isEmpty || _isDeleting) return;

    setState(() {
      if (_selectedAssetIds.length == _screenshots.length) {
        _selectedAssetIds.clear();
      } else {
        _selectedAssetIds
          ..clear()
          ..addAll(_screenshots.map((asset) => asset.id));
      }
    });
  }

  List<AssetEntity> get _selectedAssets {
    return _screenshots
        .where((asset) => _selectedAssetIds.contains(asset.id))
        .toList();
  }

  bool get _isAllSelected {
    return _screenshots.isNotEmpty &&
        _selectedAssetIds.length == _screenshots.length;
  }

  Future<void> _openLimitedPhotoPicker() async {
    await PhotoManager.presentLimited(type: RequestType.image);

    if (!mounted) return;

    await _loadScreenshots();
  }

  Future<void> _openAppSettings() async {
    await PhotoManager.openSetting();
  }

  Future<void> _showDeletePreview() async {
    final selectedAssets = _selectedAssets;

    if (selectedAssets.isEmpty || _isDeleting) return;

    final totalBytes = await _calculateTotalFileSize(selectedAssets);

    if (!mounted) return;

    final readableSize = _formatBytes(totalBytes);

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
                const Text(
                  '스크린샷 삭제 준비',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '선택한 스크린샷 ${selectedAssets.length}장을 확인해주세요.',
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
                          '예상 확보 공간 $readableSize',
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
                    itemCount: selectedAssets.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: PomuSpacing.sm),
                    itemBuilder: (context, index) {
                      return _DeletePreviewThumbnail(
                        asset: selectedAssets[index],
                      );
                    },
                  ),
                ),
                const SizedBox(height: PomuSpacing.lg),
                const Text(
                  '삭제한 항목은 사진 앱의 최근 삭제된 항목으로 이동해요.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: PomuSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();

                          await _deleteSelectedAssets(selectedAssets);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text('${selectedAssets.length}장 삭제'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteSelectedAssets(List<AssetEntity> selectedAssets) async {
    if (selectedAssets.isEmpty || _isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final requestedIds = selectedAssets.map((asset) => asset.id).toList();

      final deletedIds = await PhotoManager.editor.deleteWithIds(requestedIds);

      if (!mounted) return;

      if (deletedIds.isEmpty) {
        _showSnackBar('삭제가 취소되었거나 실패했어요.');

        setState(() {
          _isDeleting = false;
        });

        return;
      }

      final deletedIdSet = deletedIds.toSet();

      setState(() {
        _screenshots.removeWhere((asset) => deletedIdSet.contains(asset.id));

        _selectedAssetIds.removeAll(deletedIdSet);
        _isDeleting = false;
      });

      _showSnackBar('${deletedIds.length}장의 스크린샷을 최근 삭제된 항목으로 이동했어요.');
    } catch (error, stackTrace) {
      debugPrint('❌ 스크린샷 삭제 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      _showSnackBar('스크린샷을 삭제하지 못했어요.');
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

  String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '확인 불가';
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
        title: const Text(
          '스크린샷 정리',
          style: TextStyle(
            color: PomuColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (!_isLoading && _screenshots.isNotEmpty)
            TextButton(
              onPressed: _isDeleting ? null : _toggleSelectAll,
              child: Text(
                _isAllSelected ? '선택 해제' : '전체 선택',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: PomuColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
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
                totalCount: _screenshots.length,
                selectedCount: _selectedAssetIds.length,
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

          if (_screenshots.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyScreenshotView(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PomuSpacing.lg,
                0,
                PomuSpacing.lg,
                130,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final asset = _screenshots[index];
                  final isSelected = _selectedAssetIds.contains(asset.id);

                  return _ScreenshotTile(
                    asset: asset,
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
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_isLoading || _permissionDenied || _screenshots.isEmpty) {
      return null;
    }

    final selectedCount = _selectedAssetIds.length;

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
          onPressed: selectedCount == 0 || _isDeleting
              ? null
              : _showDeletePreview,
          icon: _isDeleting
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
                ? '삭제 중...'
                : selectedCount == 0
                ? '삭제할 스크린샷을 선택해주세요'
                : '선택한 $selectedCount장 삭제',
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
                  '스크린샷 $totalCount장',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedCount == 0
                      ? '삭제할 스크린샷을 선택해주세요.'
                      : '$selectedCount장을 선택했어요.',
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
          const Expanded(
            child: Text(
              '선택한 사진만 접근 중이에요. 모든 스크린샷을 보려면 접근 사진을 추가해주세요.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: PomuColors.textPrimary,
              ),
            ),
          ),
          TextButton(onPressed: onTap, child: const Text('추가')),
        ],
      ),
    );
  }
}

class _ScreenshotTile extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ScreenshotTile({
    required this.asset,
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
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize(360, 360),
                quality: 88,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Container(color: PomuColors.primaryLight);
                }

                return Image.memory(snapshot.data!, fit: BoxFit.cover);
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
            const Text(
              '정리할 스크린샷이 없어요',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: PomuColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '현재 사진 보관함에 스크린샷이 없거나\n접근 가능한 스크린샷이 없어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
            const Text(
              '사진 접근 권한이 필요해요',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: PomuColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '스크린샷을 확인하고 정리하려면\n사진 보관함 접근을 허용해주세요.',
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
              child: const Text('설정 열기'),
            ),
          ],
        ),
      ),
    );
  }
}
