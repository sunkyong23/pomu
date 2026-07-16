import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/theme/pomu_colors.dart';
import '../../core/theme/pomu_spacing.dart';
import '../../core/widgets/buttons/pomu_primary_button.dart';
import '../../core/widgets/logo/pomu_logo.dart';
import '../../l10n/app_localizations.dart';
import '../../services/photo_permission_service.dart';
import '../home/home_screen.dart';

extension _PhotoPermissionL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class PhotoPermissionScreen extends StatefulWidget {
  const PhotoPermissionScreen({super.key});

  @override
  State<PhotoPermissionScreen> createState() => _PhotoPermissionScreenState();
}

class _PhotoPermissionScreenState extends State<PhotoPermissionScreen> {
  final PhotoPermissionService _permissionService = PhotoPermissionService();

  bool _isLoading = false;

  Future<void> _requestPermission() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final PermissionState state = await _permissionService.requestPermission();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (state.hasAccess) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }

    await _showPermissionDialog();
  }

  Future<void> _showPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            dialogContext.l10n.permissionDialogTitle,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: PomuColors.textPrimary,
            ),
          ),
          content: Text(
            dialogContext.l10n.permissionDialogDescription,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: PomuColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.later),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _permissionService.openSettings();
              },
              child: Text(dialogContext.l10n.openSettings),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PomuColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PomuSpacing.lg,
            vertical: PomuSpacing.lg,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Semantics(
                label: context.l10n.appName,
                image: true,
                child: const PomuLogo(size: 88),
              ),

              const SizedBox(height: PomuSpacing.xl),

              Text(
                context.l10n.permissionTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: PomuColors.textPrimary,
                  letterSpacing: -0.7,
                  height: 1.18,
                ),
              ),

              const SizedBox(height: PomuSpacing.md),

              Text(
                context.l10n.permissionDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: PomuColors.textSecondary,
                ),
              ),

              const SizedBox(height: PomuSpacing.xl),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(PomuSpacing.md),
                decoration: BoxDecoration(
                  color: PomuColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PomuColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PrivacyIcon(),
                    const SizedBox(width: PomuSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.permissionPrivacyTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: PomuColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.permissionPrivacyDescription,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: PomuColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              Semantics(
                button: true,
                enabled: !_isLoading,
                label: context.l10n.permissionStartButton,
                child: PomuPrimaryButton(
                  text: context.l10n.permissionStartButton,
                  icon: Icons.photo_library_outlined,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _requestPermission,
                ),
              ),

              const SizedBox(height: PomuSpacing.md),

              Text(
                context.l10n.permissionBottomDescription,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: PomuColors.textSecondary),
              ),

              const SizedBox(height: PomuSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyIcon extends StatelessWidget {
  const _PrivacyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: PomuColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_outline_rounded,
        size: 22,
        color: PomuColors.primary,
      ),
    );
  }
}
