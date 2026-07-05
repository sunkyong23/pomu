import '../../models/photo_category.dart';
import 'vision_service.dart';

class CategoryMapper {
  static const double minConfidence = 0.15;

  List<PhotoCategory> mapLabels(List<VisionLabel> labels) {
    if (labels.isEmpty) {
      return [PhotoCategory.other];
    }

    final normalizedLabels = labels
        .map(
          (label) => VisionLabel(
            identifier: label.identifier.toLowerCase(),
            confidence: label.confidence,
          ),
        )
        .toList();

    final isScreenshot = _hasKeyword(
      normalizedLabels,
      _screenshotKeywords,
      minConfidence: 0.3,
    );

    final isReceipt = _hasKeyword(
      normalizedLabels,
      _receiptKeywords,
      minConfidence: 0.25,
    );

    // 스크린샷은 화면 캡처 자체가 핵심 카테고리.
    // 캡처 안에 사람/음식이 보여도 People/Food로 오염시키지 않는다.
    if (isScreenshot) {
      if (isReceipt) {
        return [PhotoCategory.screenshots, PhotoCategory.receipts];
      }

      return [PhotoCategory.screenshots];
    }

    if (isReceipt) {
      return [PhotoCategory.receipts];
    }

    final categories = <PhotoCategory>{};

    final scores = <PhotoCategory, double>{
      PhotoCategory.pets: 0,
      PhotoCategory.people: 0,
      PhotoCategory.food: 0,
      PhotoCategory.landscape: 0,
      PhotoCategory.documents: 0,
    };

    for (final label in normalizedLabels) {
      final id = label.identifier;
      final confidence = label.confidence;

      if (confidence < minConfidence) continue;

      _addScore(scores, PhotoCategory.pets, id, confidence, _petKeywords);
      _addScore(scores, PhotoCategory.people, id, confidence, _peopleKeywords);
      _addScore(scores, PhotoCategory.food, id, confidence, _foodKeywords);
      _addScore(
        scores,
        PhotoCategory.landscape,
        id,
        confidence,
        _landscapeKeywords,
      );
      _addScore(
        scores,
        PhotoCategory.documents,
        id,
        confidence,
        _documentKeywords,
      );
    }

    print('🧮 Category scores: ${scores.map((k, v) => MapEntry(k.name, v))}');

    for (final entry in scores.entries) {
      if (entry.value >= _thresholdFor(entry.key)) {
        categories.add(entry.key);
      }
    }

    if (categories.isEmpty) {
      return [PhotoCategory.other];
    }

    return categories.toList();
  }

  double _thresholdFor(PhotoCategory category) {
    switch (category) {
      case PhotoCategory.pets:
        return 0.3;
      case PhotoCategory.people:
        return 0.8;
      case PhotoCategory.food:
        return 0.45;
      case PhotoCategory.landscape:
        return 0.45;
      case PhotoCategory.documents:
        return 0.5;
      case PhotoCategory.screenshots:
      case PhotoCategory.receipts:
      case PhotoCategory.other:
        return minConfidence;
    }
  }

  void _addScore(
    Map<PhotoCategory, double> scores,
    PhotoCategory category,
    String label,
    double confidence,
    List<String> keywords,
  ) {
    if (_matches(label, keywords)) {
      scores[category] = scores[category]! + confidence;
    }
  }

  bool _hasKeyword(
    List<VisionLabel> labels,
    List<String> keywords, {
    required double minConfidence,
  }) {
    return labels.any(
      (label) =>
          label.confidence >= minConfidence &&
          _matches(label.identifier, keywords),
    );
  }

  bool _matches(String label, List<String> keywords) {
    return keywords.any(label.contains);
  }

  static const List<String> _screenshotKeywords = ['screenshot', 'screen'];

  static const List<String> _receiptKeywords = [
    'receipt',
    'invoice',
    'bill',
    'payment',
    'purchase',
    'checkout',
  ];

  static const List<String> _petKeywords = [
    'cat',
    'kitten',
    'feline',
    'dog',
    'puppy',
    'canine',
    'pet',
    'animal',
    'rabbit',
    'bird',
    'parrot',
    'hamster',
    'horse',
    'cow',
    'sheep',
  ];

  static const List<String> _peopleKeywords = [
    'person',
    'people',
    'human',
    'face',
    'portrait',
    'selfie',
    'man',
    'woman',
    'child',
    'baby',
    'adult',
    'teen',
  ];

  static const List<String> _foodKeywords = [
    'food',
    'meal',
    'dish',
    'restaurant',
    'dessert',
    'drink',
    'coffee',
    'tea',
    'cake',
    'pizza',
    'burger',
    'fruit',
    'vegetable',
    'rice',
    'bread',
    'tableware',
  ];

  static const List<String> _landscapeKeywords = [
    'landscape',
    'nature',
    'outdoor',
    'mountain',
    'sky',
    'cloud',
    'sunset',
    'sunrise',
    'beach',
    'sea',
    'ocean',
    'lake',
    'river',
    'waterfall',
    'tree',
    'forest',
    'flower',
    'park',
    'snow',
  ];

  static const List<String> _documentKeywords = [
    'document',
    'paper',
    'text',
    'book',
    'note',
    'letter',
    'form',
    'newspaper',
    'magazine',
    'printed_page',
    'chart',
    'diagram',
    'map',
  ];
}
