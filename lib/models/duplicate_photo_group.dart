import 'package:photo_manager/photo_manager.dart';

class DuplicatePhotoGroup {
  final String id;
  final List<AssetEntity> assets;

  const DuplicatePhotoGroup({required this.id, required this.assets});

  AssetEntity get keeper => assets.first;

  List<AssetEntity> get deleteCandidates {
    if (assets.length <= 1) return [];
    return assets.skip(1).toList();
  }

  int get count => assets.length;

  int get deleteCandidateCount => deleteCandidates.length;
}
