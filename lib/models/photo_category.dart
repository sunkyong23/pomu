import 'package:flutter/material.dart';

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

extension PhotoCategoryLabel on PhotoCategory {
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

  String get koreanName {
    switch (this) {
      case PhotoCategory.pets:
        return '반려동물';
      case PhotoCategory.people:
        return '사람';
      case PhotoCategory.food:
        return '음식';
      case PhotoCategory.landscape:
        return '풍경';
      case PhotoCategory.documents:
        return '문서';
      case PhotoCategory.screenshots:
        return '스크린샷';
      case PhotoCategory.receipts:
        return '영수증';
      case PhotoCategory.other:
        return '기타';
    }
  }
}

extension PhotoCategoryIcon on PhotoCategory {
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
