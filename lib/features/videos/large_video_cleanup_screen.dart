import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../l10n/app_localizations.dart';

import '../../core/widgets/buttons/pomu_delete_action_row.dart';

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

  // 파일 용량은 한 번에 너무 많이 열면 오히려 I/O가 몰릴 수 있어서
  // 4개씩만 제한적으로 병렬 처리한다.
  static const int _fileSizeConcurrency = 4;

  // 진행률 UI는 영상 하나마다 갱신하지 않고 일정 간격으로만 갱신한다.
  static const int _progressUpdateInterval = 20;

  // 화면을 오래 스크롤해도 썸네일 Future를 무한정 잡고 있지 않도록 제한한다.
  static const int _maxThumbnailCacheEntries = 48;

  static const String _sizeCacheKey = 'pomu_large_video_size_cache_v1';

  final List<_VideoEntry> _videos = [];

  // 일반 선택 모드에서 실제 선택한 ID만 보관한다.
  final Set<String> _selectedIds = {};

  // 전체 선택 모드에서는 전체 ID를 저장하지 않고,
  // 사용자가 선택 해제한 ID만 보관한다.
  final Set<String> _deselectedIds = {};

  // asset.id -> file size
  final Map<String, int> _sizeCache = {};

  // 썸네일 Future 간단 LRU 캐시
  final Map<String, Future<Uint8List?>> _thumbnailFutures = {};

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _permissionDenied = false;
  bool _selectAllMode = false;

  int _loadedFileSizeCount = 0;
  int _totalVideoCount = 0;

  // build마다 전체 리스트를 fold하지 않도록 합계를 상태로 유지한다.
  int _totalVideoBytesValue = 0;
  int _selectedBytes = 0;
  int _deselectedBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<Uint8List?> _getThumbnailFuture(AssetEntity asset) {
    final cached = _thumbnailFutures.remove(asset.id);

    if (cached != null) {
      // 최근 사용 항목을 뒤로 보내 간단한 LRU처럼 동작시킨다.
      _thumbnailFutures[asset.id] = cached;
      return cached;
    }

    final future = asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 244),
      quality: 80,
    );

    _thumbnailFutures[asset.id] = future;

    while (_thumbnailFutures.length > _maxThumbnailCacheEntries) {
      _thumbnailFutures.remove(_thumbnailFutures.keys.first);
    }

    return future;
  }

  Future<void> _loadSizeCache() async {
    _sizeCache.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sizeCacheKey);

      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        return;
      }

      for (final entry in decoded.entries) {
        final value = entry.value;

        if (value is num) {
          final size = value.toInt();

          if (size > 0) {
            _sizeCache[entry.key] = size;
          }
        }
      }
    } catch (error) {
      debugPrint('⚠️ 동영상 용량 캐시 불러오기 실패: $error');
      _sizeCache.clear();
    }
  }

  Future<void> _saveSizeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sizeCacheKey, jsonEncode(_sizeCache));
    } catch (error) {
      debugPrint('⚠️ 동영상 용량 캐시 저장 실패: $error');
    }
  }

  Future<int> _resolveVideoSize(AssetEntity asset) async {
    final cachedSize = _sizeCache[asset.id];

    if (cachedSize != null && cachedSize > 0) {
      return cachedSize;
    }

    try {
      final file = await asset.file;

      if (file == null) {
        return 0;
      }

      final size = await file.length();

      if (size > 0) {
        _sizeCache[asset.id] = size;
      }

      return size;
    } catch (error) {
      debugPrint('⚠️ 동영상 용량 확인 실패: ${asset.id} / $error');
      return 0;
    }
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
          _thumbnailFutures.clear();
          _selectedIds.clear();
          _deselectedIds.clear();

          _selectAllMode = false;
          _selectedBytes = 0;
          _deselectedBytes = 0;
          _totalVideoBytesValue = 0;
          _totalVideoCount = 0;
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

      // 메타데이터 목록은 빠르게 페이지 단위로 가져온다.
      var page = 0;

      while (assets.length < totalCount) {
        final pageAssets = await album.getAssetListPaged(
          page: page,
          size: _pageSize,
        );

        if (pageAssets.isEmpty) {
          break;
        }

        assets.addAll(pageAssets);
        page++;

        debugPrint(
          '🎥 동영상 목록 불러오는 중 '
          '${assets.length.clamp(0, totalCount)} / $totalCount',
        );
      }

      await _loadSizeCache();

      final currentAssetIds = assets.map((asset) => asset.id).toSet();

      // 사진 앱에서 이미 삭제된 영상의 오래된 캐시는 제거한다.
      _sizeCache.removeWhere((id, _) => !currentAssetIds.contains(id));

      final entries = <_VideoEntry>[];
      var processedCount = 0;

      // 캐시가 없는 영상만 실제 파일을 확인한다.
      // 첫 실행에서도 4개씩 제한적으로 병렬 처리해서 기존 직렬 처리보다 빠르다.
      for (
        var start = 0;
        start < assets.length;
        start += _fileSizeConcurrency
      ) {
        final end = (start + _fileSizeConcurrency < assets.length)
            ? start + _fileSizeConcurrency
            : assets.length;

        final batch = assets.sublist(start, end);

        final sizes = await Future.wait(
          batch.map((asset) => _resolveVideoSize(asset)),
        );

        for (var index = 0; index < batch.length; index++) {
          entries.add(
            _VideoEntry(asset: batch[index], sizeBytes: sizes[index]),
          );
        }

        processedCount += batch.length;

        if (!mounted) return;

        final shouldUpdateProgress =
            processedCount == assets.length ||
            processedCount % _progressUpdateInterval == 0;

        if (shouldUpdateProgress) {
          setState(() {
            _loadedFileSizeCount = processedCount;
          });
        }

        // 메인 isolate에 잠깐 양보해서 긴 분석 중에도 UI 응답성을 유지한다.
        await Future<void>.delayed(Duration.zero);
      }

      entries.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

      if (!mounted) return;

      final sizeById = <String, int>{
        for (final entry in entries) entry.asset.id: entry.sizeBytes,
      };

      _selectedIds.removeWhere((id) => !currentAssetIds.contains(id));
      _deselectedIds.removeWhere((id) => !currentAssetIds.contains(id));

      _selectedBytes = 0;

      for (final id in _selectedIds) {
        _selectedBytes += sizeById[id] ?? 0;
      }

      _deselectedBytes = 0;

      for (final id in _deselectedIds) {
        _deselectedBytes += sizeById[id] ?? 0;
      }

      final totalBytes = entries.fold<int>(
        0,
        (sum, entry) => sum + entry.sizeBytes,
      );

      setState(() {
        _videos
          ..clear()
          ..addAll(entries);

        _totalVideoBytesValue = totalBytes;
        _totalVideoCount = entries.length;
        _loadedFileSizeCount = entries.length;

        _thumbnailFutures.removeWhere((id, _) => !currentAssetIds.contains(id));

        if (_videos.isEmpty) {
          _selectAllMode = false;
          _selectedIds.clear();
          _deselectedIds.clear();
          _selectedBytes = 0;
          _deselectedBytes = 0;
        }

        _isLoading = false;
      });

      await _saveSizeCache();

      debugPrint(
        '✅ 큰 동영상 ${_videos.length}개 불러오기 완료 '
        '/ 캐시 ${_sizeCache.length}개',
      );
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

  bool _isEntrySelected(_VideoEntry entry) {
    if (_selectAllMode) {
      return !_deselectedIds.contains(entry.asset.id);
    }

    return _selectedIds.contains(entry.asset.id);
  }

  int get _selectedCount {
    if (_selectAllMode) {
      final count = _videos.length - _deselectedIds.length;
      return count < 0 ? 0 : count;
    }

    return _selectedIds.length;
  }

  int get _selectedTotalBytes {
    if (_selectAllMode) {
      final bytes = _totalVideoBytesValue - _deselectedBytes;
      return bytes < 0 ? 0 : bytes;
    }

    return _selectedBytes;
  }

  int get _totalVideoBytes => _totalVideoBytesValue;

  bool get _isAllSelected {
    return _videos.isNotEmpty && _selectedCount == _videos.length;
  }

  void _toggleSelection(_VideoEntry entry) {
    if (_isDeleting) return;

    setState(() {
      final id = entry.asset.id;
      final size = entry.sizeBytes;

      if (_selectAllMode) {
        if (_deselectedIds.remove(id)) {
          _deselectedBytes -= size;

          if (_deselectedBytes < 0) {
            _deselectedBytes = 0;
          }
        } else {
          _deselectedIds.add(id);
          _deselectedBytes += size;
        }

        return;
      }

      if (_selectedIds.remove(id)) {
        _selectedBytes -= size;

        if (_selectedBytes < 0) {
          _selectedBytes = 0;
        }
      } else {
        _selectedIds.add(id);
        _selectedBytes += size;
      }
    });
  }

  void _toggleSelectAll() {
    if (_videos.isEmpty || _isDeleting) return;

    setState(() {
      if (_isAllSelected) {
        _selectAllMode = false;
      } else {
        _selectAllMode = true;
      }

      _selectedIds.clear();
      _deselectedIds.clear();
      _selectedBytes = 0;
      _deselectedBytes = 0;
    });
  }

  List<_VideoEntry> get _selectedEntries {
    return _videos.where(_isEntrySelected).toList(growable: false);
  }

  Future<void> _showDeletePreview() async {
    final selectedEntries = _selectedEntries;

    if (selectedEntries.isEmpty || _isDeleting) return;

    final previewEntries = selectedEntries.take(30).toList(growable: false);

    final selectedBytes = _selectedTotalBytes;

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
                  style: const TextStyle(
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
                            _formatBytes(sheetContext, selectedBytes),
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
                    itemCount: previewEntries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: PomuSpacing.sm),
                    itemBuilder: (context, index) {
                      return _DeletePreviewTile(
                        entry: previewEntries[index],
                        formatDuration: _formatDuration,
                      );
                    },
                  ),
                ),
                const SizedBox(height: PomuSpacing.lg),
                Text(
                  sheetContext.l10n.videoMoveToRecentlyDeleted,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.md),
                PomuDeleteActionRow(
                  cancelLabel: sheetContext.l10n.cancel,
                  deleteLabel: sheetContext.l10n.videoDeleteCount(
                    selectedEntries.length,
                  ),
                  onCancel: () {
                    Navigator.of(sheetContext).pop();
                  },
                  onDelete: () async {
                    Navigator.of(sheetContext).pop();
                    await _deleteVideos(selectedEntries);
                  },
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
      final ids = selectedEntries
          .map((entry) => entry.asset.id)
          .toList(growable: false);

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

        for (final id in deletedIdSet) {
          _thumbnailFutures.remove(id);
          _sizeCache.remove(id);
        }

        _selectedIds.clear();
        _deselectedIds.clear();
        _selectAllMode = false;
        _selectedBytes = 0;
        _deselectedBytes = 0;

        _totalVideoBytesValue = _videos.fold<int>(
          0,
          (sum, entry) => sum + entry.sizeBytes,
        );

        _totalVideoCount = _videos.length;
        _isDeleting = false;
      });

      await _saveSizeCache();

      if (!mounted) return;

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

    if (!mounted) return;

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
          style: const TextStyle(
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
                selectedCount: _selectedCount,
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
                    thumbnailFuture: _getThumbnailFuture(entry.asset),
                    isSelected: _isEntrySelected(entry),
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
  final Future<Uint8List?> thumbnailFuture;
  final bool isSelected;

  final String Function(int bytes) formatBytes;
  final String Function(int seconds) formatDuration;
  final String Function(DateTime date) formatDate;

  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _VideoListTile({
    required this.entry,
    required this.thumbnailFuture,
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
