import 'package:flutter/material.dart';

import '../../theme/pomu_colors.dart';
import '../../theme/pomu_spacing.dart';

class PomuDeleteActionRow extends StatelessWidget {
  final String cancelLabel;
  final String deleteLabel;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final bool deleteEnabled;

  const PomuDeleteActionRow({
    super.key,
    required this.cancelLabel,
    required this.deleteLabel,
    required this.onCancel,
    required this.onDelete,
    this.deleteEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const buttonHeight = 56.0;
    const radius = 18.0;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(buttonHeight),
              foregroundColor: PomuColors.primary,
              backgroundColor: PomuColors.surface,
              side: const BorderSide(color: PomuColors.divider, width: 1.4),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: PomuSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(
              cancelLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: PomuSpacing.sm),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: deleteEnabled ? onDelete : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(buttonHeight),
              backgroundColor: PomuColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: PomuColors.primary.withValues(
                alpha: 0.35,
              ),
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: PomuSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 21),
            label: Text(
              deleteLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
