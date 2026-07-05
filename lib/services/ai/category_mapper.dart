import '../../models/photo_category.dart';
import 'vision_service.dart';

class CategoryMapper {
  static const double minConfidence = 0.15;

  PhotoCategory mapLabels(List<VisionLabel> labels) {
    if (labels.isEmpty) {
      return PhotoCategory.other;
    }

    final normalizedLabels = labels
        .map(
          (label) => VisionLabel(
            identifier: label.identifier.toLowerCase(),
            confidence: label.confidence,
          ),
        )
        .toList();

    // 1순위: 스크린샷
    if (_hasKeyword(
      normalizedLabels,
      _screenshotKeywords,
      minConfidence: 0.3,
    )) {
      return PhotoCategory.screenshots;
    }

    // 2순위: 영수증/청구서
    if (_hasKeyword(normalizedLabels, _receiptKeywords, minConfidence: 0.25)) {
      return PhotoCategory.receipts;
    }

    final scores = <PhotoCategory, double>{
      PhotoCategory.pets: 0,
      PhotoCategory.people: 0,
      PhotoCategory.food: 0,
      PhotoCategory.landscape: 0,
      PhotoCategory.documents: 0,
      PhotoCategory.other: 0,
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

    final bestEntry = scores.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    print('🧮 Category scores: ${scores.map((k, v) => MapEntry(k.name, v))}');

    if (bestEntry.value <= 0) {
      return PhotoCategory.other;
    }

    return bestEntry.key;
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
