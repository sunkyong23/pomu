import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../models/photo_category.dart';
import '../../services/album_settings_service.dart';

class AlbumNameSettingsScreen extends StatefulWidget {
  const AlbumNameSettingsScreen({super.key});

  @override
  State<AlbumNameSettingsScreen> createState() =>
      _AlbumNameSettingsScreenState();
}

class _AlbumNameSettingsScreenState extends State<AlbumNameSettingsScreen> {
  final AlbumSettingsService _service = AlbumSettingsService();
  final Map<PhotoCategory, TextEditingController> _controllers = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumNames();
  }

  Future<void> _loadAlbumNames() async {
    for (final category in PhotoCategory.values) {
      final customName = await _service.getCustomAlbumName(category);

      _controllers[category] = TextEditingController(text: customName ?? '');
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    for (final entry in _controllers.entries) {
      await _service.setAlbumName(entry.key, entry.value.text);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('앨범 이름이 저장되었어요')));

    Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await _service.resetAllAlbumNames();

    for (final controller in _controllers.values) {
      controller.clear();
    }

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('기본 앨범 이름으로 되돌렸어요')));
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      appBar: AppBar(
        backgroundColor: PomuColors.background,
        elevation: 0,
        title: const Text(
          '앨범 이름 설정',
          style: TextStyle(
            color: PomuColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _reset,
            child: const Text(
              '초기화',
              style: TextStyle(
                color: PomuColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: PomuColors.primary),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(PomuSpacing.lg),
              itemCount: PhotoCategory.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: PomuSpacing.md),
              itemBuilder: (context, index) {
                final category = PhotoCategory.values[index];
                final controller = _controllers[category]!;

                return _AlbumNameCard(
                  category: category,
                  controller: controller,
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PomuSpacing.lg),
          child: PomuPrimaryButton(
            text: '저장',
            icon: Icons.check_rounded,
            onPressed: _isLoading ? null : _save,
          ),
        ),
      ),
    );
  }
}

class _AlbumNameCard extends StatelessWidget {
  final PhotoCategory category;
  final TextEditingController controller;

  const _AlbumNameCard({required this.category, required this.controller});

  @override
  Widget build(BuildContext context) {
    final defaultAlbumName = 'Pomu ${category.albumName}';

    return Container(
      padding: const EdgeInsets.all(PomuSpacing.lg),
      decoration: BoxDecoration(
        color: PomuColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomuColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: PomuColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: PomuColors.primary, size: 22),
              ),
              const SizedBox(width: PomuSpacing.md),
              Expanded(
                child: Text(
                  category.koreanName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: PomuColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PomuSpacing.lg),
          const Text(
            '기본 이름',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PomuColors.textSecondary,
            ),
          ),
          const SizedBox(height: PomuSpacing.xs),
          Text(
            defaultAlbumName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: PomuColors.textPrimary,
            ),
          ),
          const SizedBox(height: PomuSpacing.md),
          const Text(
            '사용자 지정 이름',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PomuColors.textSecondary,
            ),
          ),
          const SizedBox(height: PomuSpacing.xs),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '비워두면 기본 이름 사용',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PomuColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PomuColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: PomuColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: PomuSpacing.sm),
          const Text(
            '입력하지 않으면 기본 이름으로 앨범이 생성돼요.',
            style: TextStyle(fontSize: 12, color: PomuColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
