import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../../services/scan_service.dart';
import '../scan/scan_progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScanService _scanService = ScanService();

  bool _isLoading = true;
  int _photoCount = 0;
  DateTime? _lastScan;
  List<AssetEntity> _newPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotoCount();
  }

  Future<void> _loadPhotoCount() async {
    setState(() => _isLoading = true);

    final newPhotos = await _scanService.loadNewPhotos();
    final lastScan = await _scanService.getLastScan();

    if (!mounted) return;

    setState(() {
      _newPhotos = newPhotos;
      _photoCount = newPhotos.length;
      _lastScan = lastScan;
      _isLoading = false;
    });
  }

  Future<void> _openScanProgress() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ScanProgressScreen()));

    if (!mounted) return;
    _loadPhotoCount();
  }

  @override
  Widget build(BuildContext context) {
    final hasNewPhotos = _photoCount > 0;

    return Scaffold(
      backgroundColor: PomuColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  PomuLogo(size: 32),
                  SizedBox(width: PomuSpacing.sm),
                  Text(
                    'Pomu',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: PomuColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PomuSpacing.xxl),
              const Text(
                '사진 정리를\n시작해볼까요?',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: PomuColors.textPrimary,
                  height: 1.12,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: PomuSpacing.md),
              const Text(
                '새로 추가된 사진을 찾고,\nAI가 자동으로 분류해드릴게요.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: PomuColors.textSecondary,
                ),
              ),
              const SizedBox(height: PomuSpacing.xl),
              _StatusCard(
                isLoading: _isLoading,
                photoCount: _photoCount,
                lastScan: _lastScan,
                photos: _newPhotos,
                onRefresh: _loadPhotoCount,
              ),
              const SizedBox(height: PomuSpacing.xl),
              PomuPrimaryButton(
                text: hasNewPhotos ? '사진 정리 시작' : '정리할 새 사진이 없어요',
                icon: hasNewPhotos
                    ? Icons.auto_awesome_rounded
                    : Icons.check_rounded,
                onPressed: hasNewPhotos ? _openScanProgress : null,
              ),
              const SizedBox(height: PomuSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isLoading;
  final int photoCount;
  final DateTime? lastScan;
  final List<AssetEntity> photos;
  final VoidCallback onRefresh;

  const _StatusCard({
    required this.isLoading,
    required this.photoCount,
    required this.lastScan,
    required this.photos,
    required this.onRefresh,
  });

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasNewPhotos = photoCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PomuColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: PomuSpacing.xl),
                child: CircularProgressIndicator(color: PomuColors.primary),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasNewPhotos
                      ? Icons.photo_library_outlined
                      : Icons.check_circle_rounded,
                  color: hasNewPhotos ? PomuColors.primary : PomuColors.mint,
                  size: 30,
                ),
                const SizedBox(height: PomuSpacing.md),
                Text(
                  hasNewPhotos ? '새 사진' : '모든 사진이 정리되어 있어요',
                  style: const TextStyle(
                    fontSize: 16,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.xs),
                Text(
                  '$photoCount장',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: PomuSpacing.lg),
                  _PhotoPreviewStrip(photos: photos),
                ],
                const SizedBox(height: PomuSpacing.lg),
                const Divider(height: 1),
                const SizedBox(height: PomuSpacing.lg),
                const Text(
                  '마지막 정리',
                  style: TextStyle(
                    fontSize: 16,
                    color: PomuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.xs),
                Text(
                  lastScan == null ? '아직 없음' : _formatDate(lastScan!),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: PomuColors.textPrimary,
                  ),
                ),
                const SizedBox(height: PomuSpacing.md),
                GestureDetector(
                  onTap: onRefresh,
                  child: const Text(
                    '다시 확인하기',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PomuColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: PomuSpacing.xs),
                GestureDetector(
                  onTap: () async {
                    await ScanService().resetLastScan();
                    onRefresh();
                  },
                  child: const Text(
                    '테스트용 초기화',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: PomuColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PhotoPreviewStrip extends StatelessWidget {
  final List<AssetEntity> photos;

  const _PhotoPreviewStrip({required this.photos});

  @override
  Widget build(BuildContext context) {
    final previewPhotos = photos.take(4).toList();
    final remainingCount = photos.length - previewPhotos.length;

    return SizedBox(
      height: 72,
      child: Row(
        children: List.generate(previewPhotos.length, (index) {
          final photo = previewPhotos[index];
          final isLast = index == previewPhotos.length - 1;
          final showRemaining = isLast && remainingCount > 0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == previewPhotos.length - 1 ? 0 : 8,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder(
                      future: photo.thumbnailDataWithSize(
                        const ThumbnailSize(220, 220),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return Container(color: PomuColors.primaryLight);
                        }

                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      },
                    ),
                    if (showRemaining)
                      Container(
                        color: Colors.black.withOpacity(0.45),
                        alignment: Alignment.center,
                        child: Text(
                          '+$remainingCount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
