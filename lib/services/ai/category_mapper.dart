import '../../models/photo_category.dart';
import 'vision_service.dart';

class CategoryMapper {
  PhotoCategory mapLabels(List<VisionLabel> labels) {
    final joined = labels
        .map((label) => label.identifier.toLowerCase())
        .join(' ');

    if (_containsAny(joined, [
      'cat',
      'dog',
      'pet',
      'animal',
      'rabbit',
      'bird',
    ])) {
      return PhotoCategory.pets;
    }

    if (_containsAny(joined, [
      'person',
      'face',
      'human',
      'people',
      'portrait',
    ])) {
      return PhotoCategory.people;
    }

    if (_containsAny(joined, [
      'food',
      'meal',
      'dish',
      'restaurant',
      'dessert',
      'drink',
    ])) {
      return PhotoCategory.food;
    }

    if (_containsAny(joined, [
      'mountain',
      'sky',
      'tree',
      'waterfall',
      'beach',
      'landscape',
      'nature',
      'outdoor',
    ])) {
      return PhotoCategory.landscape;
    }

    if (_containsAny(joined, [
      'document',
      'text',
      'paper',
      'receipt',
      'invoice',
      'book',
    ])) {
      return PhotoCategory.documents;
    }

    return PhotoCategory.other;
  }

  bool _containsAny(String source, List<String> keywords) {
    return keywords.any(source.contains);
  }
}
