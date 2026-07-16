import 'package:flutter/material.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../l10n/app_localizations.dart';
import '../../models/photo_category.dart';
import '../../services/album_settings_service.dart';

extension _AlbumNameSettingsL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String _localizedCategoryName(BuildContext context, PhotoCategory category) {
  switch (category) {
    case PhotoCategory.pets:
      return context.l10n.categoryPets;
    case PhotoCategory.people:
      return context.l10n.categoryPeople;
    case PhotoCategory.food:
      return context.l10n.categoryFood;
    case PhotoCategory.landscape:
      return context.l10n.categoryLandscape;
    case PhotoCategory.documents:
      return context.l10n.categoryDocuments;
    case PhotoCategory.screenshots:
      return context.l10n.categoryScreenshots;
    case PhotoCategory.receipts:
      return context.l10n.categoryReceipts;
    case PhotoCategory.other:
      return context.l10n.categoryOther;
  }
}

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
  bool _isSaving = false;
  bool _isResetting = false;

  bool get _isBusy => _isLoading || _isSaving || _isResetting;

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
    if (_isBusy) return;

    setState(() {
      _isSaving = true;
    });

    try {
      for (final entry in _controllers.entries) {
        await _service.setAlbumName(entry.key, entry.value.text);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.albumNamesSaved)));

      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _reset() async {
    if (_isBusy) return;

    setState(() {
      _isResetting = true;
    });

    try {
      await _service.resetAllAlbumNames();

      for (final controller in _controllers.values) {
        controller.clear();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.albumNamesReset)));
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
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
        title: Text(
          context.l10n.albumNameSettingsTitle,
          style: TextStyle(
            color: PomuColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isBusy ? null : _reset,
            child: Text(
              context.l10n.reset,
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
            text: _isSaving ? context.l10n.saving : context.l10n.save,
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _isBusy ? null : _save,
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
    final localizedCategoryName = _localizedCategoryName(context, category);
    final defaultAlbumName = context.l10n.defaultAlbumName(
      localizedCategoryName,
    );

    return Semantics(
      container: true,
      label: localizedCategoryName,
      child: Container(
        padding: const EdgeInsets.all(PomuSpacing.lg),
        decoration: BoxDecoration(
          color: PomuColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: PomuColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
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
                  child: Icon(
                    category.icon,
                    color: PomuColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: PomuSpacing.md),
                Expanded(
                  child: Text(
                    localizedCategoryName,
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
            Text(
              context.l10n.defaultNameLabel,
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
            Text(
              context.l10n.customNameLabel,
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
                hintText: context.l10n.albumNameEmptyHint,
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
            Text(
              context.l10n.albumNameDefaultHelp,
              style: TextStyle(fontSize: 12, color: PomuColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
