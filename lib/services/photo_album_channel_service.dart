import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoAlbumChannelService {
  static const MethodChannel _channel = MethodChannel('pomu/album');

  Future<bool> addPhotosToAlbum({
    required String albumName,
    required List<AssetEntity> photos,
  }) async {
    final result = await _channel.invokeMethod<bool>('addPhotosToAlbum', {
      'albumName': albumName,
      'assetIds': photos.map((photo) => photo.id).toList(),
    });

    return result ?? false;
  }
}
