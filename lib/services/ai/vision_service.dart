import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

class VisionLabel {
  final String identifier;
  final double confidence;

  const VisionLabel({required this.identifier, required this.confidence});

  factory VisionLabel.fromMap(Map<dynamic, dynamic> map) {
    return VisionLabel(
      identifier: map['identifier'] as String,
      confidence: (map['confidence'] as num).toDouble(),
    );
  }
}

class VisionService {
  static const MethodChannel _channel = MethodChannel('pomu/vision');

  Future<List<VisionLabel>> analyzePhoto(AssetEntity photo) async {
    final Uint8List? bytes = await photo.thumbnailDataWithSize(
      const ThumbnailSize(512, 512),
    );

    if (bytes == null) {
      print('⚠️ Thumbnail bytes null: ${photo.id}');
      return [];
    }

    print('🖼️ Thumbnail ready: ${photo.id}, ${bytes.length} bytes');

    final result = await _channel.invokeMethod<List<dynamic>>(
      'analyzeImage',
      bytes,
    );

    if (result == null) {
      print('⚠️ Vision result null: ${photo.id}');
      return [];
    }

    final labels = result
        .map((item) => VisionLabel.fromMap(item as Map<dynamic, dynamic>))
        .toList();

    print('🏷️ Vision returned ${labels.length} labels: ${photo.id}');

    return labels;
  }
}
