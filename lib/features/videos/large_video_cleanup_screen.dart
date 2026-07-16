import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../l10n/app_localizations.dart';

import 'package:video_player/video_player.dart';

extension _LargeVideoCleanupL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class LargeVideoCleanupScreen extends StatefulWidget {
  const LargeVideoCleanupScreen({super.key});

  @override
  State<LargeVideoCleanupScreen> createState() =>
      _LargeVideoCleanupScreenState();
}

class _LargeVideoCleanupScreenState extends State<LargeVideoCleanupScreen> {
  static const int _pageSize = 100;

  final List<_VideoEntry> _videos = [];
  final Set<String> _selectedIds = {};

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _permissionDenied = false;

  int _loadedFileSizeCount = 0;
  int _totalVideoCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _permissionDenied = false;
        _loadedFileSizeCount = 0;
        _totalVideoCount = 0;
      });
    }

    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.hasAccess) {
      if (!mounted) return;

      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });

      return;
    }

    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: const [
            OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );

      if (albums.isEmpty) {
        if (!mounted) return;

        setState(() {
          _videos.clear();
          _selectedIds.clear();
          _isLoading = false;
        });

        return;
      }

      final album = albums.first;
      final totalCount = await album.assetCountAsync;
      final assets = <AssetEntity>[];

      if (mounted) {
        setState(() {
          _totalVideoCount = totalCount;
        });
      }

      var page = 0;

      while (assets.length < totalCount) {
        final pageAssets = await album.getAssetListPaged(
          page: page,
          size: _pageSize,
        );

        if (pageAssets.isEmpty) break;

        assets.addAll(pageAssets);
        page++;

        debugPrint(
          '🎥 동영상 목록 불러오는 중 '
          '${assets.length.clamp(0, totalCount)} / $totalCount',
        );
      }

      final entries = <_VideoEntry>[];

      for (var index = 0; index < assets.length; index++) {
        final asset = assets[index];
        var sizeBytes = 0;

        try {
          final file = await asset.file;

          if (file != null) {
            sizeBytes = await file.length();
          }
        } catch (error) {
          debugPrint('⚠️ 동영상 용량 확인 실패: ${asset.id} / $error');
        }

        entries.add(_VideoEntry(asset: asset, sizeBytes: sizeBytes));

        if (!mounted) return;

        setState(() {
          _loadedFileSizeCount = index + 1;
        });
      }

      entries.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

      if (!mounted) return;

      setState(() {
        _videos
          ..clear()
          ..addAll(entries);

        _selectedIds.removeWhere(
          (id) => !_videos.any((entry) => entry.asset.id == id),
        );

        _isLoading = false;
      });

      debugPrint('✅ 큰 동영상 ${_videos.length}개 불러오기 완료');
    } catch (error, stackTrace) {
      debugPrint('❌ 동영상 불러오기 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(context.l10n.videoLoadFailed);
    }
  }

  void _toggleSelection(_VideoEntry entry) {
    if (_isDeleting) return;

    setState(() {
      final id = entry.asset.id;

      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    if (_videos.isEmpty || _isDeleting) return;

    setState(() {
      if (_isAllSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_videos.map((entry) => entry.asset.id));
      }
    });
  }

  bool get _isAllSelected {
    return _videos.isNotEmpty && _selectedIds.length == _videos.length;
  }

  List<_VideoEntry> get _selectedEntries {
    return _videos
        .where((entry) => _selectedIds.contains(entry.asset.id))
        .toList();
  }

  int get _selectedTotalBytes {
    return _selectedEntries.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);
  }

  int get _totalVideoBytes {
    return _videos.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);
  }

  Future<void> _showDeletePreview() async {
    final selectedEntries = _selectedEntries;

    if (selectedEntries.isEmpty || _isDeleting) return;

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
                  sheetContext.l10n.videoDeletePreparationTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sheetContext.l10n.videoDeleteReview(selectedEntries.length),
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
                          sheetContext.l10n.estimatedSpace(
                            _formatBytes(sheetContext, _selectedTotalBytes),
                          ),
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
                  height: 94,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedEntries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: PomuSpacing.sm),
                    itemBuilder: (context, index) {
                      return _DeletePreviewTile(
                        entry: selectedEntries[index],
                        formatDuration: _formatDuration,
                      );
                    },
                  ),
                ),
                const SizedBox(height: PomuSpacing.lg),
                Text(
                  sheetContext.l10n.videoMoveToRecentlyDeleted,
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
                        child: Text(sheetContext.l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: PomuSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();

                          await _deleteVideos(selectedEntries);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          sheetContext.l10n.videoDeleteCount(
                            selectedEntries.length,
                          ),
                        ),
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

  Future<void> _deleteVideos(List<_VideoEntry> selectedEntries) async {
    if (selectedEntries.isEmpty || _isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final ids = selectedEntries.map((entry) => entry.asset.id).toList();

      final deletedIds = await PhotoManager.editor.deleteWithIds(ids);

      if (!mounted) return;

      if (deletedIds.isEmpty) {
        setState(() {
          _isDeleting = false;
        });

        _showSnackBar(context.l10n.deleteCanceledOrFailed);
        return;
      }

      final deletedIdSet = deletedIds.toSet();

      setState(() {
        _videos.removeWhere((entry) => deletedIdSet.contains(entry.asset.id));

        _selectedIds.removeAll(deletedIdSet);
        _isDeleting = false;
      });

      _showSnackBar(context.l10n.videoDeletedSuccess(deletedIds.length));
    } catch (error, stackTrace) {
      debugPrint('❌ 동영상 삭제 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      _showSnackBar(context.l10n.videoDeleteFailed);
    }
  }

  Future<void> _showVideoPreview(_VideoEntry entry) async {
    _showSnackBar(context.l10n.videoLoadingOriginal);

    final file = await entry.asset.originFile;

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (file == null) {
      _showSnackBar(context.l10n.videoOriginalLoadFailed);
      return;
    }

    debugPrint('🎬 동영상 경로: ${file.path}');
    debugPrint('🎬 파일 존재: ${await file.exists()}');
    debugPrint('🎬 파일 크기: ${await file.length()}');

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _VideoPreviewScreen(
          file: file,
          sizeText: _formatBytes(context, entry.sizeBytes),
          dateText: _formatDate(entry.asset.createDateTime),
        ),
      ),
    );
  }

  Future<void> _openAppSettings() async {
    await PhotoManager.openSetting();
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minuteText:$secondText';
    }

    return '$minutes:$secondText';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}.$month.$day';
  }

  String _formatBytes(BuildContext context, int bytes) {
    if (bytes <= 0) return context.l10n.unableToCheckSize;

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
          context.l10n.homeLargeVideoCleanupTitle,
          style: TextStyle(
            color: PomuColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (!_isLoading && _videos.isNotEmpty)
            TextButton(
              onPressed: _isDeleting ? null : _toggleSelectAll,
              child: Text(
                _isAllSelected
                    ? context.l10n.screenshotDeselectAll
                    : context.l10n.screenshotSelectAll,
                style: const TextStyle(
                  color: PomuColors.primary,
                  fontWeight: FontWeight.w800,
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
    if (_permissionDenied) {
      return _PermissionDeniedView(onOpenSettings: _openAppSettings);
    }

    if (_isLoading) {
      return _LoadingView(
        current: _loadedFileSizeCount,
        total: _totalVideoCount,
      );
    }

    return RefreshIndicator(
      color: PomuColors.primary,
      onRefresh: _loadVideos,
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
              child: _VideoSummaryCard(
                videoCount: _videos.length,
                totalBytes: _totalVideoBytes,
                selectedCount: _selectedIds.length,
                selectedBytes: _selectedTotalBytes,
                formatBytes: (bytes) => _formatBytes(context, bytes),
              ),
            ),
          ),
          if (_videos.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyVideoView(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                PomuSpacing.lg,
                0,
                PomuSpacing.lg,
                130,
              ),
              sliver: SliverList.separated(
                itemCount: _videos.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: PomuSpacing.sm),
                itemBuilder: (context, index) {
                  final entry = _videos[index];

                  return _VideoListTile(
                    entry: entry,
                    isSelected: _selectedIds.contains(entry.asset.id),
                    formatBytes: (bytes) => _formatBytes(context, bytes),
                    formatDuration: _formatDuration,
                    formatDate: _formatDate,
                    onTap: () => _toggleSelection(entry),
                    onLongPress: () => _showVideoPreview(entry),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context) {
    if (_isLoading || _permissionDenied || _videos.isEmpty) {
      return null;
    }

    final selectedCount = _selectedIds.length;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          PomuSpacing.lg,
          PomuSpacing.sm,
          PomuSpacing.lg,
          PomuSpacing.md,
        ),
        decoration: const BoxDecoration(
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
                ? context.l10n.deleting
                : selectedCount == 0
                ? context.l10n.videoSelectToDelete
                : context.l10n.videoDeleteSelectedWithSize(
                    selectedCount,
                    _formatBytes(context, _selectedTotalBytes),
                  ),
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

class _VideoEntry {
  final AssetEntity asset;
  final int sizeBytes;

  const _VideoEntry({required this.asset, required this.sizeBytes});
}

class _LoadingView extends StatelessWidget {
  final int current;
  final int total;

  const _LoadingView({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final hasTotal = total > 0;
    final progress = hasTotal ? current / total : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PomuSpacing.xl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(PomuSpacing.lg),
          decoration: BoxDecoration(
            color: PomuColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: PomuColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.video_library_rounded,
                size: 42,
                color: PomuColors.primary,
              ),
              const SizedBox(height: PomuSpacing.md),
              Text(
                context.l10n.videoFindingLargeVideos,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: PomuColors.textPrimary,
                ),
              ),
              const SizedBox(height: PomuSpacing.md),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                color: PomuColors.primary,
                backgroundColor: PomuColors.primaryLight,
              ),
              const SizedBox(height: PomuSpacing.md),
              Text(
                hasTotal
                    ? context.l10n.videoCheckingSizes(current, total)
                    : context.l10n.videoLoadingList,
                style: const TextStyle(
                  fontSize: 14,
                  color: PomuColors.textSecondary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.l10n.videoMayTakeTime,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: PomuColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoSummaryCard extends StatelessWidget {
  final int videoCount;
  final int totalBytes;
  final int selectedCount;
  final int selectedBytes;
  final String Function(int bytes) formatBytes;

  const _VideoSummaryCard({
    required this.videoCount,
    required this.totalBytes,
    required this.selectedCount,
    required this.selectedBytes,
    required this.formatBytes,
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: PomuColors.primaryLight,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.video_library_rounded,
              color: PomuColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: PomuSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.videoSummary(
                    videoCount,
                    formatBytes(totalBytes),
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  selectedCount == 0
                      ? context.l10n.videoSortedBySize
                      : context.l10n.videoSelectedSummary(
                          selectedCount,
                          formatBytes(selectedBytes),
                        ),
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

class _VideoListTile extends StatelessWidget {
  final _VideoEntry entry;
  final bool isSelected;

  final String Function(int bytes) formatBytes;
  final String Function(int seconds) formatDuration;
  final String Function(DateTime date) formatDate;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _VideoListTile({
    required this.entry,
    required this.isSelected,
    required this.formatBytes,
    required this.formatDuration,
    required this.formatDate,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final asset = entry.asset;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(PomuSpacing.sm),
          decoration: BoxDecoration(
            color: PomuColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? PomuColors.primary : PomuColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                height: 86,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: FutureBuilder<Uint8List?>(
                        future: asset.thumbnailDataWithSize(
                          const ThumbnailSize(320, 260),
                          quality: 85,
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data == null) {
                            return Container(color: PomuColors.primaryLight);
                          }

                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          formatDuration(asset.duration),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PomuSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatBytes(entry.sizeBytes),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: PomuColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDate(asset.createDateTime),
                      style: const TextStyle(
                        fontSize: 13,
                        color: PomuColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.videoLongPressPreview,
                      style: TextStyle(
                        fontSize: 12,
                        color: PomuColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? PomuColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? PomuColors.primary
                        : PomuColors.textSecondary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 19,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletePreviewTile extends StatelessWidget {
  final _VideoEntry entry;
  final String Function(int seconds) formatDuration;

  const _DeletePreviewTile({required this.entry, required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 94,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FutureBuilder<Uint8List?>(
              future: entry.asset.thumbnailDataWithSize(
                const ThumbnailSize(220, 200),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Container(color: PomuColors.primaryLight);
                }

                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.64),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                formatDuration(entry.asset.duration),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVideoView extends StatelessWidget {
  const _EmptyVideoView();

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
              context.l10n.videoEmptyTitle,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: PomuColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.videoEmptyDescription,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: PomuColors.textSecondary),
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
              Icons.video_library_outlined,
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
              context.l10n.videoPermissionDescription,
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

class _VideoPreviewScreen extends StatefulWidget {
  final File file;
  final String sizeText;
  final String dateText;

  const _VideoPreviewScreen({
    required this.file,
    required this.sizeText,
    required this.dateText,
  });

  @override
  State<_VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<_VideoPreviewScreen> {
  VideoPlayerController? _controller;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.file(widget.file);

      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(1);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
      });

      await controller.play();

      debugPrint(
        '✅ 동영상 초기화 완료 '
        '/ 크기: ${controller.value.size} '
        '/ 길이: ${controller.value.duration}',
      );
    } catch (error, stackTrace) {
      debugPrint('❌ 동영상 초기화 실패: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      if (controller.value.position >= controller.value.duration) {
        await controller.seekTo(Duration.zero);
      }

      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minuteText:$secondText';
    }

    return '$minutes:$secondText';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildVideoArea(controller)),

            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            if (controller != null && controller.value.isInitialized)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _buildControls(controller),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea(VideoPlayerController? controller) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 14),
            Text(
              context.l10n.videoPreparing,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 46,
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.videoPlaybackFailed,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Text(
          context.l10n.videoPlayerUnavailable,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final width = controller.value.size.width;
    final height = controller.value.size.height;

    if (width <= 0 || height <= 0) {
      return Center(
        child: Text(
          context.l10n.videoSizeUnavailable,
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePlayPause,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: width,
              height: height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(PomuSpacing.md),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                colors: const VideoProgressColors(
                  playedColor: PomuColors.primary,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white24,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(
                      value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${_formatDuration(value.position)}'
                      ' / '
                      '${_formatDuration(value.duration)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.sizeText} · ${widget.dateText}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
