import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum PhotoCategory {
  pets,
  people,
  food,
  landscape,
  documents,
  screenshots,
  receipts,
  other,
}

extension PhotoCategoryPresentation on PhotoCategory {
  /// Stable English suffix used by existing album creation and saved settings.
  ///
  /// Keep this value stable so previously created album names and preferences
  /// continue to work across app-language changes.
  String get albumName {
    switch (this) {
      case PhotoCategory.pets:
        return 'Pets';
      case PhotoCategory.people:
        return 'People';
      case PhotoCategory.food:
        return 'Food';
      case PhotoCategory.landscape:
        return 'Landscape';
      case PhotoCategory.documents:
        return 'Documents';
      case PhotoCategory.screenshots:
        return 'Screenshots';
      case PhotoCategory.receipts:
        return 'Receipts';
      case PhotoCategory.other:
        return 'Others';
    }
  }

  /// Localized category label for user-facing screens.
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case PhotoCategory.pets:
        return l10n.categoryPets;
      case PhotoCategory.people:
        return l10n.categoryPeople;
      case PhotoCategory.food:
        return l10n.categoryFood;
      case PhotoCategory.landscape:
        return l10n.categoryLandscape;
      case PhotoCategory.documents:
        return l10n.categoryDocuments;
      case PhotoCategory.screenshots:
        return l10n.categoryScreenshots;
      case PhotoCategory.receipts:
        return l10n.categoryReceipts;
      case PhotoCategory.other:
        return l10n.categoryOther;
    }
  }

  IconData get icon {
    switch (this) {
      case PhotoCategory.pets:
        return Icons.pets_rounded;
      case PhotoCategory.people:
        return Icons.people_alt_rounded;
      case PhotoCategory.food:
        return Icons.restaurant_rounded;
      case PhotoCategory.landscape:
        return Icons.landscape_rounded;
      case PhotoCategory.documents:
        return Icons.description_rounded;
      case PhotoCategory.screenshots:
        return Icons.screenshot_monitor_rounded;
      case PhotoCategory.receipts:
        return Icons.receipt_long_rounded;
      case PhotoCategory.other:
        return Icons.folder_rounded;
    }
  }
}
